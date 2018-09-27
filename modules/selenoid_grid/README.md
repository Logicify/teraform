# Selenoid Grid Module

This module sets up a cluster of selenoid instances with a Go Grid Router load balancer (ggr).

## Table of Content

1. [Components](#components)
1. [Deployment Schema](#deployment-schema)
1. [Deployment Hints](#deployment-hints)
1. [Operation Hints](#operation-hints)
1. [Writing Tests](#writing-tests)

## Components

* [selenoid](https://aerokube.com/selenoid/latest/) is a powerful Go implementation of original Selenium hub code. It 
is using Docker to launch browsers.  
* [ggr (Go Grid Router)](https://aerokube.com/ggr/latest/) is a lightweight load balancer used to create big Selenium 
clusters.
* [selenoid-ui](https://aerokube.com/selenoid-ui/latest/) - simple status monitoring web UI for selenoid.
* [ggr-ui](https://aerokube.com/ggr-ui/latest/) - standalone daemon that automatically collects /status information 
from multiple Selenoid instances and returns it as a single /status API. When this daemon is running you can use 
Selenoid UI to see the state of the entire cluster.

Although not a separate component, but [configuration manager](https://aerokube.com/cm/latest/) is used to configure
selenoid instances.

Check documentation for individual components to reveal hidden features.

## Deployment Schema

Working deployment consists of at minimum two instances: one running balancer and one running selenoid. Selenoid 
instances are all members of an auto-scaling group. This allows one to easily configure number of worker instances
required and change it upon need. **No automatic scaling** is in place.

Below is a schematic components deployment diagram showing relations between components.

```       
 Workers                                                   
 Cluster       +---------------------------------+         
               |                                 |         
       +--------------+    +--------------+      |         
       |              |    |              |      |         
       |    selenoid  |    |    selenoid  -------+         
       |              |    |              |      |         
       +--------------+    +-------|------+      |         
               |                   |             |         
 ----------------------------------------------------------
 Balancer      |                   |             |         
               |   +-----------+   |      +------|-----+   
               |   |           |   |      |            |   
               +----    ggr    ----+      |   ggr-ui   |   
                   |           |          |            |   
                   +-----|-----+          +------|-----+   
                         |                       |         
                         |              +--------|-------+ 
                         |              |                | 
                         |              |  selenoid-ui   | 
                     run tests          |                | 
                         |              +--------|-------+ 
 ------------------------|-----------------------|---------
 Not part of             |                  view status    
 infrastructure          |                       |         
             +-----------+-----------+   +-------+-------+ 
             |                       |   |               | 
             |   selenium test       |   |    browser    | 
             |                       |   |               | 
             +-----------------------+   +---------------+                                                                                                                                
```

Ggr discovers selenoid nodes by querying AWS auto-scaling group instances on regular interval (3 min by default) and 
requesting `/status` API endpoint of each.

By default selenium interface is running on `4444` port and monitoring ui is on `80`

## Deployment Hints

### Subnets

You have control over subnet placement of worker nodes and load balancer. It is up to you if you place them in same or
different subnets. Though it is recommended to put nodes into a private subnet (well, there is no sane reason not to 
do that).

#### WARNING

This setup allows running selenium tests without authentication. Think how you would secure load balancer selenium port
from unauthorised usage. Few options include:

1. use `selenium_hub_trusted_networks` module property to restrict access to known hosts only
1. put load balancer in private subnet.

### Security groups

Security groups by default are configured in a way to only allow minimum communication between balancer and nodes. This 
literally means that by default selenoid nodes don't have access to any external resources. You need to configure 
security groups properly in order to perform actual testing of your webapp.

### Availability zones

There is no direct way to put nodes in different AZs. Though you can assign nodes to subnets in different AZs and
instances will be places accordingly.

### AMI

This module was developed and tested with Amazon Linux. It may not work with other distros.

### Output Variables

Module has following output variables available:

* `lb_instance_id`- instance ID of ggr balancer. Can be used to associate additional resources with the instance. For
example an Elastic IP.
* `nodes_asg_id` - auto-scaling group ID where worker instances are running.

## Operation Hints

### Browsers & versions

Selenoid nodes are configured to run same set of browsers which can be governed by `cm_browsers` and 
`cm_last_versions`. Syntax of `cm_browsers` is briefly described 
[here](https://aerokube.com/cm/latest/#_example_commands).

In most cases you will want `N` last versions of chrome and firefox browsers. This grid setup is Linux based and thus
Windows browsers are not supported. Though it is principally possible to add Windows hosts to the setup.

#### Updating browsers to latest versions

When new version of necessary browser is out you would like to be able to run tests with it. Easiest way to update to
latest versions is to terminate worked instances from AWS console. Auto-scaling group will recreate them for you and
once they are provisioned they will have latest available browser images.

**CAVEAT:** since selenoid runs browsers in docker you would expect *latest version of your browser docker image*.
Which means that it may not be as fresh as you required browser. You can find available browser docker images 
on [selenoid dockerhub](https://hub.docker.com/u/selenoid/).

#### Advanced browser configuration 

`cm_browser` string is not well documented. Though should you need some specific versions of browser you can put them
in like this:
```
firefox:59.0;firefox:60.0;chrome
```
It will install firefox verions 59 and 60 and `cm_last_versions` of chrome.

## Writing Tests

### Selenoid advanced features

Selenoid && GGR support number of features not available in original Selenium. These include

* video recording
* session logs storage
* custom screen resolution
* per-session 
  * timezones
  * environment variables (locale)
  * hosts file entries
  * DNS servers
  
Take a look at [Advanced Features](https://aerokube.com/selenoid/latest/#_advanced_features) chapter of selenoid doc.

### Caveats

#### Maximize Chrome window

There seem to be a bug in chrome which doesn't allow to use `driver.maximize_window()` with it. Two workarounds exist:

* wait for selenoid guys to fix this with a window manager
* use `set_window_size` instead:
  ```
  driver.set_window_size(1980, 1080, driver.current_window_handle)
  ```
  combine this with [capability to set screen resolution](https://aerokube.com/selenoid/latest/#_custom_screen_resolution_screenresolution).
  
#### Retrieving logs\videos

Logs\video are accessed by selenium session ID on same host\port you use to run your tests. To get session ID of your
running test you can use `driver.session_id`.

It would be helpful to print URLs to logs & video in the beginning of your test:
```python
from selenium import webdriver

selenium_host = 'http://13.56.166.3:4444'

driver = webdriver.Remote('{0}/wd/hub'.format(selenium_host), {
    'browserName': 'firefox',
    'enableVNC': True,
    'enableVideo': True,
    'screenResolution': '1980x1080x24'
})

print("Test video: {0}/video/{1}".format(selenium_host, driver.session_id))
print("Test logs: {0}/logs/{1}".format(selenium_host, driver.session_id))
```
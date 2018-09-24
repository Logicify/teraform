#!/usr/bin/env python27

"""A tool that queries instances of given AWS auto-scale group for their selenoid /status'es and merges then together"""

# MIT License
#
# Copyright (c) 2017 Logicify
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import sys

import argparse
import httplib
import json
import subprocess
from distutils.version import LooseVersion
from xml.etree import ElementTree as ET


def eprint(text):
    print >> sys.stderr, text


def get_asg_instance_ids(region, asg_name):
    cmd = 'aws autoscaling describe-auto-scaling-groups --region {0} '\
          '--query AutoScalingGroups[?AutoScalingGroupName==`{1}`].Instances[].InstanceId --output text'
    output = subprocess.check_output(cmd.format(region, asg_name).split(' '))
    return output.strip().split('\t')


def get_instance_private_ip(region, instance_id):
    cmd = 'aws ec2 describe-instances --region {0} --instance-ids {1} '\
          '--query Reservations[].Instances[].PrivateIpAddress --output text'
    output = subprocess.check_output(cmd.format(region, instance_id).split(' '))
    return next(iter(filter(None, output.split('\n'))), None)


def xml_serialize(browsers):
    xml_root = ET.Element("qa:browsers", {'xmlns:qa': 'urn:config.gridrouter.qatools.ru'})
    for name, versions in browsers.iteritems():
        default_version = LooseVersion('0.0.0.0.0')
        xml_browser = ET.SubElement(xml_root, 'browser', {
            'name': name
        })

        for version_number, regions in versions.iteritems():
            version = LooseVersion(version_number)
            if version > default_version:
                default_version = version
            xml_version = ET.SubElement(xml_browser, 'version', {'number': version_number})
            for region, hosts in regions.iteritems():
                xml_region = ET.SubElement(xml_version, 'region', {'name': region})
                for host in hosts:
                    ET.SubElement(xml_region, 'host', {
                        'name': host['name'],
                        'port': str(host['port']),
                        'count': str(host['count'])
                    })
        xml_browser.set('defaultVersion', default_version.__str__())
    return ET.tostring(xml_root)


def selenoid_status(ip, selenoid_port):
    conn = httplib.HTTPConnection(ip, port=selenoid_port)
    try:
        conn.request("GET", "/status")
        resp = conn.getresponse()
        rs_json = json.loads(resp.read())

        return rs_json
    finally:
        conn.close()


def merge_browsers(region, dest, selenoid_ip, selenoid_port, status):
    instance_browsers = status['browsers']
    eprint(instance_browsers)

    for browsr, versions in instance_browsers.iteritems():
        browser_node = dest.setdefault(browsr, dict())
        for ver, _ in versions.iteritems():
            browser_node.setdefault(ver, {}).setdefault(region, []).append({
                'name': selenoid_ip,
                'port': selenoid_port,
                'count': status['total']
            })


def main(region_param, asg_name_param, selenium_port_param):
    region = region_param
    asg_name = asg_name_param
    selenoid_port = selenium_port_param

    instance_ids = get_asg_instance_ids(region, asg_name)
    ips = [get_instance_private_ip(region, iid) for iid in instance_ids]
    eprint(ips)

    browsers = dict()
    for selenoid_ip in ips:
        try:
            status = selenoid_status(selenoid_ip, selenoid_port)
            merge_browsers(region, browsers, selenoid_ip, selenoid_port, status)
        except Exception:
            eprint(sys.exc_info()[0])

    eprint(browsers)

    ggr_quota = xml_serialize(browsers)
    print ggr_quota


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Query auto-scaling group, get /status on each and merge results as XML'
    )
    parser.add_argument('region', help='AWS region instances are running in')
    parser.add_argument('asg-name', help='Name of auto-scaling group where Selenoid instances are running')
    parser.add_argument('--port', type=int, default=4444, help='Selenoid port')
    args = vars(parser.parse_args())
    if not args['region'] or not args['asg-name']:
        parser.print_help()
        sys.exit(1)
    eprint(args)
    main(args['region'], args['asg-name'], args['port'])


# -*- coding: utf-8 -*-
#!/usr/bin/python

import subprocess
import sys
import requests

def not_in(x):
    not_in_filters = ['ProfileUUID', 'development', 'sigh_org']
    is_in = False
    for not_in_filter in not_in_filters:
        is_in = not_in_filter in x
        if is_in:
            break

    return not is_in

def run_fastlane(mode):
    subprocess.check_output(['fastlane', 'create'])
    print "\t=> Mode: %s" % mode
    print "\t=> fastlane match %s" % mode
    output = subprocess.check_output(['fastlane', 'match', mode])
    output = ''.join(output.split()).split('ios|')[2].split('|ProfileName')[0].split('|')
    output = [x for x in output if x]
    output = [x for x in output if not_in(x)]
    output = ''.join(output)
    return output

def send_uuids(dev_uuid, store_uuid, org_code):
    print "\t=> Development: %s" % dev_uuid
    print "\t=> AppStore: %s" % store_uuid
    authorization_key = 'e6005c3173671458fee3b322a73178ca2c900ab8b433c302dbd560ec0ed71570'
    action = 'save_ios_uuids'

    url = "https://consola-api/organizations/%s/circleci/webhook?authorization=%s&action=%s&devUUID=%s&storeUUID-=%s" % (org_code, authorization_key, action, devUUID, storeUUID)
    r = requests.post(url)
    print r.json()

if __name__ == '__main__':
    org_code = sys.argv[1]
    print "=> Running fastlane match"
    dev_uuid = run_fastlane('development')
    store_uuid = run_fastlane('appstore')
    print "=> Send UUIDS to Consola"
    send_uuids(dev_uuid, store_uuid, org_code);

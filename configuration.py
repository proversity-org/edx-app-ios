
# -*- coding: utf-8 -*-
#!/usr/bin/python

import os
import re
import subprocess
import sys

FILENAMES = [
	'edX.entitlements',
    'Source/edX-Info.plist',
    'edX.xcodeproj/project.pbxproj'
]

DEVELOPMENT_TEAM = '773JA72FQU'
EDX_DEVELOPMENT_TEAM = '57UCUYGPA2'
PRO_DEV_UUID = 'aea18a23-fe25-4446-9e19-291ffb82c59f'
PRO_STORE_UUID = '1e8e4e06-34c2-48a7-8182-4f4216359bc2'
EDX_REVERSED_URL = 'org.edx.mobile'

def apply_configuration(
    filename,
    name,
    org_code,
    version,
    edx_version,
    dev_uuid,
    store_uuid
):
    if filename is None or \
        name is None or \
        org_code is None or \
        version is None or \
        edx_version is None or \
        dev_uuid is None or \
        store_uuid is None:
        return
    
    with open(filename, "r") as file:
        file_str = file.read()

    if filename == 'edX.entitlements':
        file_str = entitlements_configuration(file_str, org_code)

    if filename == 'Source/edX-Info.plist':
        file_str =\
            info_plist_configuration(file_str, name, version, edx_version)

    if filename == 'edX.xcodeproj/project.pbxproj':
        file_str =\
            project_configuration(file_str, org_code, dev_uuid, store_uuid)

    with open(filename, "w") as f:
        f.write(file_str)

def entitlements_configuration(file_str, org_code):
    replacement = 'org.proversity.{}'.format(org_code)
    return re.sub(r'\b{}\b'.format(EDX_REVERSED_URL), replacement, file_str)

def info_plist_configuration(file_str, name, version, edx_version):
    name_replacement = '{}'.format(name)
    version_replacement = '{}'.format(version)
    file_str = re.sub(r'\bedX\b', name_replacement, file_str)
    file_str = re.sub(r'\bed ex\b', name_replacement, file_str)
    return file_str
    # return file_str.replace(edx_version, version_replacement)

def project_configuration(file_str, org_code, dev_uuid, store_uuid):
    file_str = re.sub(r'\bAutomatic\b', 'Manual', file_str)
    file_str =\
        re.sub(r'\b{}\b'.format(PRO_DEV_UUID), dev_uuid, file_str)

    file_str =\
        re.sub(r'\b{}\b'.format(PRO_STORE_UUID), store_uuid, file_str)

    file_str =\
        re.sub(
            r'\b{}\b'.format(EDX_REVERSED_URL),
            'org.proversity.{}'.format(org_code),
            file_str
        )

    file_str =\
        re.sub(
            r'\b{}\b'.format(EDX_DEVELOPMENT_TEAM),
            DEVELOPMENT_TEAM,
            file_str
        )

    return file_str

if __name__ == '__main__':
    org_code = sys.argv[1]
    name = sys.argv[2]
    version = sys.argv[3]
    edx_version = sys.argv[4]
    dev_uuid = sys.argv[5]
    store_uuid = sys.argv[6]
    org_code = org_code.lower()
    for filename in FILENAMES:
        apply_configuration(
            filename=filename,
            name=name,
            org_code=org_code,
            version=version,
            edx_version=edx_version,
            dev_uuid=dev_uuid,
            store_uuid=store_uuid
        )

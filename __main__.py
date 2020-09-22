#!/usr/bin/python3
# #############################################
#
# updated by ...: Loreto Notarantonio
# Version ......: 22-09-2020 15.38.27
#
# #############################################

import sys; sys.dont_write_bytecode = True
import os, shutil
from   pathlib import Path

import subprocess
import json
# import yaml #PyYAML
import pyaml

from LnLib.yamlLoaderLN import loadYamlFile
from LnLib.nameSpaceLN import RecursiveNamespace
from LnLib.colorLN import LnColor; C=LnColor()
from LnLib.runCommand import runCommand, wsl_to_win_path

from Source.parseInputLN import parseInput
from Source.readInconfigDir import readInConfDir
from Source.replaceText import replaceData



######################################
# sample call:
#
######################################
if __name__ == '__main__':
    prj_name='FreeFileSync'
    os.environ['Prj_Name']=prj_name # potrebbe usarla loadYamlFile()

    ''' read Main configuration file '''
    dConfig=loadYamlFile(f'conf/{prj_name}.yml', resolve=True, fPRINT=False)
    nsConfig=RecursiveNamespace(**dConfig)



    ''' parsing input '''
    args, inp_log, dbg=parseInput(profiles=dConfig['profiles'].keys(), color=LnColor())

    if args.action=='profile':
        profile=dConfig['profiles'][args.name]
        if dbg.debug:
            print()
            pyaml.p(profile, indent=4)
            print()
        profile=RecursiveNamespace(**dConfig['profiles'][args.name])

    else:
        if args.servers:
            pyaml.p('-----', dConfig['servers'], indent=4)
        elif args.directories:
            pyaml.p('-----', dConfig['directories'], indent=4)
        elif args.profiles:
            pyaml.p('-----', dConfig['profiles'], indent=4)
        else:
            print()
            pyaml.p(dConfig, indent=4)
            print()
        sys.exit()

    ''' INCLUDE list '''
    _incl_list=['<Include>']
    if profile.include:
        for item in profile.include:
            _incl_list.append(f'<Item>{item}</Item>')
    else:
        _incl_list.append(f'<Item>*</Item>')
    _incl_list.append('</Include>')

    ''' EXCLUDE list '''
    _excl_list=['<Exclude>']
    if profile.exclude:
        for item in profile.exclude:
            _excl_list.append(f'<Item>{item}</Item>')
    else:
        _excl_list.append(f'<Item>*</Item>')
    _excl_list.append('</Exclude>')



    ''' PATHs
        samples:
            K:/Filu/LnDisk/LnPi/LnPi31_BACKUP_2020-06/home/pi
            sftp://pi@192.168.1.31:22/home/pi|chan=10|agent
    '''
    def prepare_path(ptr, folder=''):
        if folder:
            if not folder in profile.folders:
                print(f'''
                    folder <{folder}> is not recognised.
                    Please enter one (or more) BLANK separated
                    of the following:'''.replace('  ', ' '))

                pyaml.p('folder list', profile.folders,  indent=8, width=60)
                print()
                sys.exit(1)
            folder=f'/{folder}'

        if ptr.server:
            my_path=ptr.path
            my_path=f'{ptr.server}{my_path}{folder}'
        else:
            full_path=f'{ptr.path}{folder}'
            if Path(full_path).is_dir():
                my_path=wsl_to_win_path(f'{ptr.path}{folder}') # da errore per un path che non esiste
            else:
                print(f'''
                    path <{full_path}> not exists.
                    Please create it before to continue'''.replace('  ', ' '))
                print()
                sys.exit(1)

        if ptr.options: my_path=f'{my_path}|{ptr.options}'
        return my_path



    # pyaml.p(stringToBeChanged, indent=4)

    CMD=[]
    CMD.append(nsConfig.main.freefilesync.exe)

    dynprofile_dir=nsConfig.main.freefilesync.dynprofile_dir
    template_data=readInConfDir(profile.template_file)
    my_folders=args.sub_folders if args.sub_folders else profile.folders

    for folder_name in my_folders:
        # if folder_name=='LnPi':
        #     import pdb; pdb.set_trace() # by Loreto
        stringToBeChanged = {
            'SourcePATH':   prepare_path(profile.source, folder=folder_name),
            'DestPATH':     prepare_path(profile.destination, folder=folder_name),
            'SyncType':     profile.sync_type,
            'Exclude':      '\n'.join(_excl_list),
            'Include':      '\n'.join(_incl_list),
            }

        temp_file=f'{dynprofile_dir}/{folder_name}.ffs_gui'
        replaceData(template_data, changing_data=stringToBeChanged, output_file=temp_file)
        CMD.append(wsl_to_win_path(temp_file))

    # add global setting config file (lastused is cleaned)
    shutil.copyfile(nsConfig.main.freefilesync.xml_setting, nsConfig.main.freefilesync.xml_setting_wk)
    CMD.append(wsl_to_win_path(nsConfig.main.freefilesync.xml_setting_wk))


    for line in CMD:
        print('  ', line)

    if dbg.go:
        print('Starting....')
        p=subprocess.Popen(CMD, close_fds=True) # no-WAIT
    else:
        print()
        print("     please enter --go to un FreeFileSync")
        print()

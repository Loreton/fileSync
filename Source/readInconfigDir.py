# #############################################
#
# updated by ...: Loreto Notarantonio
# Version ......: 21-08-2020 08.18.33
#
# #############################################
import  sys; sys.dont_write_bytecode=True
import  os

from    pathlib import Path
import  zipfile
import  io


#######################################################
# filename:  deve essere relative-path in quanto deve
#   poter essere letto anche all'interno dello zip file
#######################################################
def readInConfDir(filename):
    # check if I'm inside a ZIP file or directory
    _this_filepath=Path(sys.argv[0]).resolve()

    content=[]

    #---- read inside zip file
    if zipfile.is_zipfile(_this_filepath):
        _I_AM_ZIP=True
        zip_filename=_this_filepath
        z=zipfile.ZipFile(zip_filename, "r")
        with z.open(filename) as f:
            _data=f.read()
        _buffer=io.TextIOWrapper(io.BytesIO(_data))
        # contents =io.TextIOWrapper(io.BytesIO(_data), encoding='iso-8859-1', newline='\n')# def get_config(yaml_filename):
        for line in _buffer:
            content.append(line)

    else: # qui devo mettere il path completo perchè non so quale sia la mia currDir
        script_path=_this_filepath.parent # ... then up one level
        filename=script_path / filename
        with open(filename, 'r') as f:
            content=f.readlines() # splitted in rows
            # content=f.read() # single string

    return content
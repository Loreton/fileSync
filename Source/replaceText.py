# #############################################
#
# updated by ...: Loreto Notarantonio
# Version ......: 21-08-2020 15.59.36
#
# #############################################



# ######################################################
# #
# ######################################################
def replaceData(input_data, *, changing_data={}, output_file=None):
    if isinstance (input_data, list):
        newData=input_data[:]
        isLIST=True
    else:
        newData=input_data
        isLIST=False

    for key, val in changing_data.items():
        key='${'+key+'}'
        if isLIST:
            for inx, line in enumerate(newData):
                newData[inx]=line.replace(key, val)
        else:
            newData = newData.replace(key, val)
    data_changed=not (newData==input_data)
    # print(f' data changed: {data_changed}')




    # Write file
    if output_file:
        with open(output_file, 'w') as file:
            if isLIST:
                for line in newData:
                    file.write(line)
            else:
                file.write(newData)

    return newData


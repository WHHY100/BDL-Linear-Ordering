from bin.classes.getDataBDL_API import BDLApi
import pathlib


def __main__():

    # current path
    path = pathlib.Path(__file__).parent.resolve()

    # =====================================================================================
    # DEF OF URLS TO DOWNLOAD (BDL API)
    # name|url|headers|name file
    # FILE: config_url_names.conf
    # PARAMETERS:
    # data_conf[0] -> name
    # data_conf[1] -> url
    # data_conf[2] -> headers
    # data_conf[3] -> name file
    # =====================================================================================

    with open(str(path) + '/config_url_names.conf') as file:
        line = file.readlines()
        for i in line:
            # replace special char in line - if used
            i = i.replace('"', '')
            # replace end of line character
            i = i.replace('\n', '')
            data_conf = i.split('|')

            result = BDLApi().data_from_api(data_conf[2], data_conf[3], data_conf[1], path)

            print("Result of saving " + data_conf[0] + ": " + str(result))

    input("Press Enter to continue...")

    return 0


__main__()


# https://bdl.stat.gov.pl/api/v1/subjects?format=xml&page=3&page-size=10
# https://bdl.stat.gov.pl/api/v1/subjects?parent-id=G403
# https://bdl.stat.gov.pl/api/v1/Variables?subject-id=P2497
# https://bdl.stat.gov.pl/api/v1/data/by-variable/64428?format=xml&unit-level=2
# https://api.stat.gov.pl/Home/BdlApi

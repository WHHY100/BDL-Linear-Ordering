import requests
import json


class BDLApi:

    # directs the operation in a class
    @classmethod
    def data_from_api(cls, headers, name_file, url, current_path) -> bool:

        try:
            json_file = cls.download_json(url)
            tab = cls.create_tab_values(headers, json_file)
            result = cls.save_to_csv(name_file, tab, current_path)

            if result == 1:
                return True

            return False

        except ValueError:

            return False

    # download json from api
    @classmethod
    def download_json(cls, url) -> json:
        response = requests.get(url)
        json_file = response.content
        loaded_jon = json.loads(json_file)

        return loaded_jon['results']

    # create array with downloaded values
    @classmethod
    def create_tab_values(cls, headers, json_file) -> list:
        id_csv = 1
        tab_csv = [headers + "\n"]

        for i in json_file:
            for j in i['values']:
                tab_csv.append(str(id_csv) + ";" + i['name'] + ";" + j['year'] + ";" + str(j['val']) + "\n")
                id_csv = id_csv + 1

        return tab_csv

    # save data to csv file
    @classmethod
    def save_to_csv(cls, name_file, tab, current_path) -> int:

        file = open(str(current_path) + "/" + name_file, 'w')

        for i in tab:
            file.writelines(i)

        file.close()

        return 1

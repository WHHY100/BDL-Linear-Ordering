# BDL-Linear-Ordering

* [Dane](#Dane)
* [Konfiguracja skryptu](#Konfiguracja_skryptu)
* [Prezentacja wyników](#Wizualizacja)
* [Wykorzystana technologia](#Technologia)

## Dane

Dane wykorzystywane w projekcie zostały pobrane z Banku Danych Lokalnych (Główny Urząd Statystyczny) przy pomocy ogólnodostępnego API udostępnionego przez GUS.

API: https://api.stat.gov.pl/Home/BdlApi

## Konfiguracja_skryptu

Konfiguracja zmiennych pobieranych z API zapisywana jest w pliku "config_url_names.conf". Domyślnie ustawionych jest tam 11 zmiennych wraz z adresem url pozwalającym 
na pobranie danych.

<b>Struktura linku url:</b> "tytuł_csv| link_do_api| nagłowki_csv_rozdzielone_średnikiem| lokalizacja_do_zapisu"

<b>Przykładowy adres:</b> "inflation_rate|htt<span>ps://bdl</span>.stat.gov.pl/api/v1/data/by-variable/217230?format=json&unit-level=2&page-size=16|id;area;year;inflation_rate|data/inflation_rate.csv"

Po skonfigurowaniu odpowiednich danych wejściowych w pliku "config_url_names.conf" wystarczy włączyć program "main.py" znajdujący się w katalogu głównym i obserwować wyniki
pobierania danych w konsoli.

## Wizualizacja

W oparciu o 10 wybranych zmiennych z Banku Danych Lokalnych został skonstruowany ranking województw wskazujący w którym z obszarów w Polsce żyje się najlepiej.

Pod uwagę były brane takie zmienne jak:
- wskaźnik inflacji w poszczególnych województwach
- średnie wynagrodzenie
- średnia cena jednego metra kwadratowego nieruchomości
- stopa bezrobocia rejestrowanego
- liczba zarejestrowanych nowych samochodów
- liczba ludzi na jedno miejsce w szpitalu
- długość dróg (w km) na 100 km kwadratowych powierzchni
- zgony w wypadkach drogowych
- liczba popełnianych przestępstw o charakterze kryminalnym
- liczba kradzieży

Zmienne zostały podzielone na stymulanty (im wyższe tym lepiej dla regionu - np. średnie wynagrodzenie) i destymulanty (im niższe tym lepiej dla regionu - np. liczba kradzieży).

W oparciu o wyliczoną taksonomiczną miarę rozwoju, stworzony został wykres obrazujący poziom taksonomicznej miary rozwoju w latach 2010-2020 w poszczególnych województwach.

![ranking wojewodztw](https://github.com/WHHY100/BDL-Linear-Ordering/blob/main/%23SAS/result_img/Summary_all_years.jpg?raw=true)

W latach 2010 - 2013 województwo mazowieckie przodowało pod względem jakości życia w rankingu porządkowania liniowego ułożonym według wybranych zmiennych. Następnie w latach 
2014 - 2019 na przedzie wylądowało województwo śląskie spychając poprzedniego lidera na drugą pozycję. W roku 2020 pod względem jakości życia województwo mazowieckie znowu 
plasowało się na pierwszym miejscu.

W badanym okresie czasowym w rankingu porządkowania liniowego najgorzej prezentowały się województwa: lubuskie, warmińsko - mazurskie i zachodniopomorskie zajmując ostatnie
miejsca w rankingu.

![ranking wojewodztw](https://github.com/WHHY100/BDL-Linear-Ordering/blob/main/%23SAS/result_img/Summary_%20%20%20%202020.jpg?raw=true)

Na wykresie powyżej przedstawiony jest ostatni rok porządkowania liniowego województw. Najwyższą taksonomiczną miarę rozwoju w tym roku osiągnęło województwo mazowieckie 
powracając na pozycję lidera rankingu obrazującego jakość życia mieszkańców poszczególnych regionów. Na ostatnim miejscu uplasowało się województwo warmińsko-mazurskie.

## Technologia

Python 3.9 / PyCharm

*SAS Studio* ® w SAS® OnDemand

Wersja: *9.4_M6*

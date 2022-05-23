# from bs4 import BeautifulSoup
# import requests
# from requests_html import HTMLSession

# url = 'https://go.documentation.sas.com/doc/en/pgmsascdc/v_025/allprodsactions/actionSetsByName.htm'

# session = HTMLSession()
# r = session.get(url)
# # r.html.render()

# soup = BeautifulSoup(r.html, 'html.parser')

# tables = [
#     [
#         [td.get_text(strip=True) for td in tr.find_all('td')] 
#         for tr in table.find_all('tr')
#     ] 
#     for table in soup.find_all('table')
# ]


import dryscrape

sess = dryscrape.Session()
sess.visit('https://go.documentation.sas.com/doc/en/pgmsascdc/v_025/allprodsactions/actionSetsByName.htm')
source = sess.body()

soup = bs.BeautifulSoup(source,'lxml')
js_test = soup.find('p', class_='jstest')
print(js_test.text)
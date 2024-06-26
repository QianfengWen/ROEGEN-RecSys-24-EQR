import requests
from bs4 import BeautifulSoup

def get_article_links(category_url):
    response = requests.get(category_url)
    soup = BeautifulSoup(response.content, 'html.parser')
    # Adjust the following line to match the HTML structure of the category page
    # For example, if links are within <a> tags under <div class="category-page">
    links = soup.select('.mw-category-group a')
    # content = soup.find(id='mw-content-ltr')
    # titles, contextList = [], []
    # if content:
    #     for ul in content.find_all('ul'):
    #         for li in ul.find_all('li'):
    #             a_tag = li.find('a', href=True)
    #             if a_tag and a_tag.text:
    #                 print(a_tag.text)

    article_links = []
    for link in links:
        article_url = link.get('href')
        if article_url:
            article_links.append(article_url)

    return article_links

def scrape_article(article_url):
    response = requests.get(article_url)
    soup = BeautifulSoup(response.content, 'html.parser')
    
    # Adjust the following line to match the HTML structure of the article page
    content = soup.select_one('.mw-body-content').get_text()
    
    return content

def get_titlename(article_url):
    response = requests.get(article_url)
    soup = BeautifulSoup(response.content, 'html.parser')
    # content = soup.select_one('.ext-wpb-pagebanner h1')

    try:
        content = soup.select('.ext-geocrumbs-breadcrumbs bdi')[-1].get_text()
    except IndexError: # list empty, likely just returning title is fine
        content = soup.select_one('.ext-wpb-pagebanner h1')
        return content.string
    # error directory catch
    if '/' in content:
        content = soup.select_one('.ext-wpb-pagebanner h1')
        if '/' in content.string:
            content = content.string.replace('/', '-')
            return content
        return content.string

    return content # title

listofurl = ['https://en.wikivoyage.org/wiki/Category:Star_cities']

for category_url in listofurl:
    article_links = get_article_links(category_url)


    for link in article_links:
        cont = scrape_article("https://en.wikivoyage.org"+link)
        article2 = get_titlename("https://en.wikivoyage.org"+link)
        # print(f"Content of {link}:\n", article_content[:500])  # Print the first 500 characters of the article content
        # print("\n" + "-"*80 + "\n")
        filename = 'wikivoyage_data/'+article2+'.txt'
        with open(filename, 'w', encoding='utf-8') as textfile:
            textfile.write(cont)

''' "https://en.wikivoyage.org"+link '''

# article2 = get_titlename("https://en.wikivoyage.org/wiki/A_Coru%C3%B1a")
# cont = scrape_article("https://en.wikivoyage.org/wiki/A_Coru%C3%B1a")
# print(article2)

# filename = 'wikivoyage_data/'+article2+'.txt'
# with open(filename, 'w', encoding='utf-8') as textfile:
#     textfile.write(cont)


# PARSE GET RID OF THE DISTRICTS SECTION TO AVOID "red light district" for example confusion
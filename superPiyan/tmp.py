import requests
from bs4 import BeautifulSoup 
# url = "https://huggingface.co/models?search=ocr"
# url = "https://huggingface.co/models?search=tts"

# print(model_elements)
# folder = 'ChatModels'
folder = 'TTSModels'
# folder = 'OCRModels'
import os
if not os.path.exists(folder):
    os.makedirs(folder)



base_url = "https://huggingface.co"
# print(f"Found {len(model_elements)} model elements.")
model_info = []
for i in range(10):
    url = f"https://huggingface.co/models?p={i}&sort=trending&search=tts"
    response = requests.get(url)
    text = response.text
    soup = BeautifulSoup(text, 'html.parser')
    model_elements = soup.find_all('article')

    for model in model_elements:
        title_element = model.find('h4')
        link = model.find('a', href=True)
        img = model.find('img')
        if title_element:
            title = title_element.text.strip()
            url_link = link['href'] if link else None
            if url_link:
                main_info = base_url + url_link
                img_data = requests.get(main_info).text
                img_soup = BeautifulSoup(img_data, 'html.parser')
                detailed_info = img_soup.find_all('dd')
                try:
                    download_last_month = detailed_info[1].text if len(detailed_info) > 1 else detailed_info[0].text
                    download_last_month = download_last_month.replace('\t', '').replace('\n', '').replace('\t1', '').replace('\t2', '').replace('\t3', '').replace('\t4', '').replace('\t5', '').strip()

                except Exception as e:
                    print(f"Error extracting download_last_month: {e}")
                    continue
                from lxml import html
                doc = html.fromstring(img_data)
                xpath = "/html/body/div[1]/main/div[2]/section[2]/div[3]/div/div[2]/div[1]/div[2]"
                els = doc.xpath(xpath)
                if els:
                    parameters = els[0].text_content().strip()
                else:
                    parameters = None


                # extract list of elements under the specified parent XPath
                parent_xpath = "/html/body/div[1]/main/div[2]/section[2]/div[7]/div"
                parents = doc.xpath(parent_xpath)
                model_tree = []
                if parents:
                    parent = parents[0]
                    # find elements whose class contains both 'flex' and 'gap-1.5'
                    items = parent.xpath(
                        ".//*[contains(concat(' ', normalize-space(@class), ' '), ' flex ') and contains(concat(' ', normalize-space(@class), ' '), ' gap-1.5 ')]"
                    )
                    for it in items:
                        txt = it.text_content().strip()
                        if txt:
                            # for i in txt:
                            txt = txt.replace('\t', '').replace('\n', '').replace('\t1', '').replace('\t2', '').replace('\t3', '').replace('\t4', '').replace('\t5', '').strip()
                            # "".join(i)
                            model_tree.append(txt)

                print(download_last_month)
                print(parameters)
                print(model_tree)
                img_tag = img_soup.find_all('img')
                img_url = img_tag[2]['src'] if len(img_tag) > 2 else None
                # print(img_url)
                if img_url and img_url.startswith('http') and 'imgur' not in img_url:
                    try:
                        with open(os.path.join(folder, f"{title.replace('/', '')}.jpg"), 'wb') as img_file:
                            img_content = requests.get(img_url).content
                            img_file.write(img_content)

                        import PIL.Image as Image
                        img_name = f"{title.replace('/', '')}.jpg"
                        try: 
                            with Image.open(os.path.join(folder, img_name)) as img:
                                img = img.convert("RGB")
                                img.thumbnail((128, 128))
                                img.save(os.path.join(folder, img_name))
                                img_name = f"{title.replace('/', '')}"
                                
                        except Exception as e:
                            print(f"Error processing image {img_name}: {e}")
                            os.remove(os.path.join(folder, f"{title.replace('/', '')}.jpg"))

                            img_name = "hugging_face_logo"







                    except Exception as e:
                        img_name = "hugging_face_logo"
                else:
                    img_name = "hugging_face_logo"
            model_info.append({
                'title': title,
                'url': base_url + url_link,
                'image': img_name,
                'parameters': parameters,
                'download_last_month': download_last_month,
                'model_tree': model_tree
            })
        else:
            print("No title found for this model.")
import json
with open(f'superPiyan/superPiyan/{folder}_info.json', 'w') as f:
    json.dump(model_info, f, indent=4)

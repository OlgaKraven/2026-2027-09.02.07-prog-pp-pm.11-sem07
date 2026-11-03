"""Create the editable empty report form and shared figure plan."""
import pathlib,json
from docx import Document
from docx.shared import Mm,Pt,RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT,WD_CELL_VERTICAL_ALIGNMENT,WD_ROW_HEIGHT_RULE
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
R=pathlib.Path(__file__).resolve().parents[1]
FIGURES=[
('Исходная область и контрольные данные','Указать БД, количества таблиц, сумму остатков и историческую сумму до изменения.'),
('Каталог из БД и готовый вход','Показать ФИО, поля каталога, собственные модели и цену.'),
('Совместный поиск фильтр и сортировка','Записать ввод, категорию, порядок и ожидаемые модели.'),
('Карточка модели и доступные размеры','Показать полный ряд и исключение нулевого размера из покупки.'),
('Ошибка количества и исправленный ввод','Указать неправильное и исправленное значение, сообщение и результат.'),
('Корзина с двумя размерными позициями','Показать разные размеры, количества и предварительную сумму.'),
('Отмена неподтверждённого заказа','Сравнить заголовки, строки и остатки до и после отмены.'),
('Подтверждённый заказ и его данные в БД','Сохранить order_id, customer_id, строки, unit_price и уменьшение остатков.'),
('Отказ второй позиции и полный откат','Показать причину отказа и неизменность всех исходных данных.'),
('Список заказов и состав выбранного заказа','Показать дату, ФИО, производство, размер, количество, цену и сумму.'),
('Заказ менеджера другому клиенту','Сопоставить текущего сотрудника и customer_id заказа.'),
('Отказ от удаления и подтверждённое удаление','Показать предупреждение, неизменность после отказа и возврат после подтверждения.'),
('Удаление одной и последней строки администратором','Указать остатки обеих позиций, состояние оставшейся строки и исчезновение пустого заказа.'),
('Изменение даты и запрет для менеджера','Показать допустимую дату, отказ будущей дате и ограничение роли.'),
('Историческая цена после изменения текущей цены','Сопоставить product.price и сохранённую unit_price до и после.'),
('Пороги суммарного остатка 3 4 5 и 6','Сопоставить сумму по размерам, подсветку и подписи мало/много для четырёх случаев.'),
('Первое индивидуальное условие','Привести точную формулировку своей карточки, статус и собственные данные.'),
('Второе индивидуальное условие','Привести точную формулировку своей карточки, статус и собственные данные. Для расширения указать выполнение либо что оно не включено в базовую приёмку.'),
('Восстановленная копия и повторный заказ','Показать имя новой БД, контрольные числа и результат чтения и заказа после восстановления.'),
('Передача проекта и ссылка на репозиторий','Показать опубликованный состав проекта и подтвердить отсутствие локальных настроек и паролей.')]
(R/'content/evidence-plan.json').write_text(json.dumps([{'number':i,'caption':t,'evidence':e} for i,(t,e) in enumerate(FIGURES,1)],ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
doc=Document();sec=doc.sections[0];sec.page_width=Mm(210);sec.page_height=Mm(297);sec.left_margin=Mm(30);sec.right_margin=Mm(20);sec.top_margin=sec.bottom_margin=Mm(20);sec.footer_distance=Mm(10)
for name in ['Normal','Title','Heading 1','Heading 2','Heading 3','Caption','TOC Heading','TOC 1','TOC 2']:
 try:s=doc.styles[name]
 except KeyError:s=doc.styles.add_style(name,1)
 s.font.name='Times New Roman';s.font.size=Pt(14);s.font.color.rgb=RGBColor(0,0,0);s.paragraph_format.line_spacing=1.5;s.paragraph_format.first_line_indent=Mm(12.5);s.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY;s.paragraph_format.space_after=Pt(0);s.paragraph_format.widow_control=True
 rf=s.element.get_or_add_rPr().get_or_add_rFonts()
 for a in list(rf.attrib):del rf.attrib[a]
 for a in ['ascii','hAnsi','cs','eastAsia']:rf.set(qn('w:'+a),'Times New Roman')
 for tag in ['w:pBdr','w:autoRedefine']:
  for node in s.element.findall('.//'+qn(tag)):node.getparent().remove(node)
for name in ['TOC 1','TOC 2']:
 s=doc.styles[name];s.font.size=Pt(12);s.paragraph_format.line_spacing=1.2;s.paragraph_format.first_line_indent=Mm(0);s.paragraph_format.space_before=Pt(0);s.paragraph_format.space_after=Pt(0)
for name in ['Title','Heading 1','TOC Heading']:
 s=doc.styles[name];s.font.size=Pt(16);s.font.bold=True;s.font.all_caps=True;s.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.CENTER;s.paragraph_format.first_line_indent=Mm(0);s.paragraph_format.space_after=Pt(12);s.paragraph_format.keep_with_next=True
cap=doc.styles['Caption'];cap.font.size=Pt(12);cap.font.italic=False;cap.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.CENTER;cap.paragraph_format.first_line_indent=Mm(0);cap.paragraph_format.line_spacing=1;cap.paragraph_format.space_after=Pt(12)
f=sec.footer.paragraphs[0];f.alignment=WD_ALIGN_PARAGRAPH.CENTER;f.paragraph_format.first_line_indent=Mm(0);field=OxmlElement('w:fldSimple');field.set(qn('w:instr'),'PAGE');f._p.append(field)
doc.add_paragraph('Отчёт по производственной практике ПМ 11',style='Title')
for line in ['Разработка администрирование и защита баз данных','Группа ____________________','Студент ____________________','Предметная область ____________________','Номер варианта ____________________','Период практики ____________________','Ссылка на репозиторий проекта ____________________']:
 p=doc.add_paragraph(line);p.paragraph_format.first_line_indent=Mm(0);p.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.CENTER
doc.add_paragraph('Форма для самостоятельного заполнения. Вставить собственные данные, результаты и снимки. Демонстрационные числа не являются ответом индивидуального варианта.')
doc.add_page_break();doc.add_paragraph('СОДЕРЖАНИЕ',style='TOC Heading');p=doc.add_paragraph();toc=OxmlElement('w:fldSimple');toc.set(qn('w:instr'),'TOC \\o "1-2" \\h \\z \\u');p._p.append(toc)
doc.add_page_break();doc.add_paragraph('1. Исходные условия',style='Heading 1')
for line in ['Назначение приложения и область: ____________________','Среда и версия СУБД: ____________________','Рабочая БД и источник исходных данных: ____________________','Готовые компоненты и выполненные самостоятельно доработки: ____________________','Таблица подстановок образца на собственную область: ____________________']:doc.add_paragraph(line)
doc.add_paragraph('2. Выполнение и проверка',style='Heading 1')
for i,(title,evidence) in enumerate(FIGURES,1):
 p=doc.add_paragraph(f'2.{i}. {title}',style='Heading 2');p.paragraph_format.keep_with_next=True
 p=doc.add_paragraph(evidence);p.paragraph_format.keep_with_next=True
 for line in ['Исходные данные и ожидаемый результат: ____________________','Выполненные действия и фактические значения: ____________________']:
  p=doc.add_paragraph(line);p.paragraph_format.keep_with_next=True
 tab=doc.add_table(rows=1,cols=1);tab.alignment=WD_TABLE_ALIGNMENT.CENTER;tab.autofit=False;tab.columns[0].width=Mm(160);tab.rows[0].height=Mm(55);tab.rows[0].height_rule=WD_ROW_HEIGHT_RULE.AT_LEAST
 pr=tab.rows[0]._tr.get_or_add_trPr();pr.append(OxmlElement('w:cantSplit'));tab.cell(0,0).vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
 borders=OxmlElement('w:tblBorders')
 for edge in ['top','left','bottom','right']:
  n=OxmlElement('w:'+edge);n.set(qn('w:val'),'single');n.set(qn('w:sz'),'5');n.set(qn('w:color'),'D9D9D9');borders.append(n)
 tab._tbl.tblPr.append(borders);p=tab.cell(0,0).paragraphs[0];p.alignment=WD_ALIGN_PARAGRAPH.CENTER;p.paragraph_format.first_line_indent=Mm(0);p.paragraph_format.keep_with_next=True;p.add_run('МЕСТО ДЛЯ СОБСТВЕННОГО СКРИНШОТА').font.size=Pt(12)
 p=doc.add_paragraph(f'Рисунок {i} — {title}',style='Caption');p.paragraph_format.keep_with_next=True
 doc.add_paragraph('Вывод и объяснение расхождений: ____________________')
doc.add_paragraph('3. Итоговая проверка',style='Heading 1')
doc.add_paragraph('Перечислить выполненные обязательные проверки, дополнительные условия и отдельно расширения. Для невыполненного сценария указать причину, не заменяя его вымышленным результатом.')
doc.add_paragraph('Ссылка на репозиторий проекта: ____________________')
doc.add_paragraph('Проверка запуска из новой копии и состав переданных файлов: ____________________')
doc.add_paragraph('4. Заключение',style='Heading 1');doc.add_paragraph('Полученный результат, возникшие затруднения и способы их устранения: ____________________')
doc.add_paragraph('5. Использованные источники',style='Heading 1');doc.add_paragraph('Указать реально использованные материалы с названием, URL и датой обращения: ____________________')
doc.core_properties.author='';doc.core_properties.last_modified_by='';doc.core_properties.title='Форма отчёта по производственной практике ПМ.11';doc.core_properties.comments=''
setting=OxmlElement('w:updateFields');setting.set(qn('w:val'),'true');doc.settings.element.append(setting)
(R/'forms').mkdir(exist_ok=True);doc.save(R/'forms/Форма отчёта ПП ПМ.11.docx')
print('Created empty Word form with 20 captioned screenshot slots')

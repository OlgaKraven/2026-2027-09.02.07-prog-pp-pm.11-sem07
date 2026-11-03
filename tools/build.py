"""Build student pages, portable archives, and paginated PDFs from course.json."""
import json,pathlib,html,re,shutil,zipfile,hashlib,textwrap,os,copy
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER,TA_JUSTIFY,TA_LEFT
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.platypus import BaseDocTemplate,PageTemplate,Frame,Paragraph,Spacer,Table,TableStyle,KeepTogether,PageBreak,Image,Preformatted
from reportlab.platypus.tableofcontents import TableOfContents

R=pathlib.Path(__file__).resolve().parents[1];SITE=R/'site';DL=SITE/'downloads';DL.mkdir(exist_ok=True)
D=json.loads((R/'content/course.json').read_text(encoding='utf-8'));BASE=D['meta']['site_url']
esc=lambda s:html.escape(str(s),quote=True)
def paras(s):
 return ''.join('<p>'+re.sub(r'https?://[^\s<]+',lambda m:f'<a href="{m[0]}">{m[0]}</a>',esc(x)).replace('\n','<br>')+'</p>' for x in s.split('\n\n'))
def imagefile(b):return R/b.get('path',b.get('src','')).replace('../','')
def codeof(b):
 if 'code' in b:return b['code']
 path=next(x['path'] for x in D['code_files'] if x['name']==b['code_file'])
 lines=(R/path).read_text(encoding='utf-8').splitlines()
 a,z=b['code_lines'];return '\n'.join(lines[a:z])
def block(b,i):
 if b['kind']=='code':inner='<pre><code>'+esc(codeof(b))+'</code></pre>'
 elif b['kind']=='image':
  f=imagefile(b);return f'<figure><img src="assets/screenshots/{esc(f.name)}" alt="{esc(b.get("title",""))}"><figcaption>{esc(b.get("title",""))}. {esc(b.get("text",""))}</figcaption></figure>'
 else:inner=paras(b.get('text',''))
 check='<p class="check"><strong>Проверка.</strong> '+esc(b['check'])+'</p>' if b.get('check') else ''
 tag='<span class="tag">Расширение</span>' if b.get('extension') else ''
 return f'<li class="step"><span class="num">{i}</span><section class="card">{tag}<h3>{esc(b["title"])}</h3>{inner}{check}</section></li>'
def chapter(s,num,anchor):
 refs='<p class="refs">Подробный разбор: '+', '.join(f'<a href="lessons.html#ref-{n}">справочник {n}</a>' for n in s.get('refs',[]))+'.</p>' if s.get('refs') else ''
 note='<p class="provided">Готовый компонент. Изучить и проверить интеграцию; создавать повторно не требуется.</p>' if s.get('provided') else ''
 return f'<article id="{anchor}" class="lesson"><header><small>{esc(num)}</small><h2>{esc(s["title"])}</h2></header>{note}<ol class="route">'+''.join(block(b,i) for i,b in enumerate(s['blocks'],1))+'</ol>'+refs+'</article>'
def buttons(items):return '<div class="actions">'+''.join(f'<a class="button" href="{p}">{n}</a>' for p,n in items)+'</div>'
def page(title,body,active):
 return '<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+esc(title)+' — ПП ПМ.11</title><link rel="stylesheet" href="assets/style.css"><link rel="icon" href="assets/favicon.svg"></head><body><a class="skip" href="#main">К содержанию</a><nav>'+''.join(f'<a href="{p}"'+(' aria-current="page"' if p==active else '')+'>'+n+'</a>' for p,n in [('index.html','Задание и файлы'),('lessons.html','Методические рекомендации'),('areas.html','Предметные области')])+'</nav><main id="main">'+body+'</main></body></html>'
def put(path,text):(SITE/path).write_text(text,encoding='utf-8')
links=[('downloads/pm11-source.zip','Исходный комплект со всеми вариантами'),('downloads/ShopDb-demo.zip','Образец для сверки'),('downloads/report-template.docx','Пустая форма отчёта Word'),('downloads/assignment.pdf','Методические рекомендации PDF'),('downloads/guide.pdf','Предметные области PDF')]
intro='<div class="hero"><p>Производственная практика ПМ.11</p><h1>Приложение с базой данных</h1><p>Каталог своей области, оформление заказа и действия сотрудников.</p></div>'
assignment=''.join(chapter(s,'1. Задание','assignment') for s in D['assignment'])
files=''.join(chapter(s,'2. Файлы для работы','files') for s in D['files'])+buttons(links)
put('index.html',page('Задание',intro+assignment+files,'index.html'))
toc='<section class="contents"><h2>Порядок работы</h2><ol>'+''.join(f'<li><a href="#step-{i}">{esc(s["title"])}</a></li>' for i,s in enumerate(D['guide'],1))+'</ol><p><a href="#reference">Подробный справочник с объяснениями и кодом</a></p></section>'
route=''.join(chapter(s,f'3.{i}. Основной маршрут',f'step-{i}') for i,s in enumerate(D['guide'],1))
refhead='<div class="hero" id="reference"><p>Справочник к основному маршруту</p><h2>Объяснения и код образца Пара</h2><p>Разделы готовых компонентов служат для понимания и проверки. Операции заказа дорабатываются в своём проекте по основному маршруту.</p></div>'
reference=''.join(chapter(s,f'Справочник {i}',f'ref-{i}') for i,s in enumerate(D['reference'],1))
put('lessons.html',page('Методические рекомендации',intro+toc+route+refhead+reference,'lessons.html'))
def area(a):
 b=[T for T in a['blocks'] if T['title'] not in ['Исходная точка и материалы']]
 return '<article class="area" id="variant-'+str(a['id'])+'"><header><small>Вариант '+f'{int(a["id"]):02}'+'</small><h2>'+esc(a['title'])+'</h2></header><div class="identity"><p><strong>Индивидуальная работа</strong><br>'+esc(a['subject'])+'</p><p><strong>Образец Пара</strong><br>Объясняет способ, его данные не заменяют собственные.</p></div><ol class="route">'+block(dict(kind='text',title='С чего начать',text=a['start']),1)+block(dict(kind='text',title='Порядок работы',text=a['route'],check=a['mapping']),2)+''.join(block(t,i) for i,t in enumerate(b,3))+'</ol>'+buttons([('downloads/pm11-source.zip','Исходный комплект'),(f'downloads/pm11-variant-{int(a["id"]):02}.zip','Отдельный архив этой области'),('lessons.html#step-1','Начать по методике')])+'</article>'
areatoc='<section class="contents"><h2>Назначенный вариант</h2><ol>'+''.join(f'<li><a href="#variant-{a["id"]}">{esc(a["title"])}</a></li>' for a in D['areas'])+'</ol></section>'
put('areas.html',page('Предметные области',intro+files+areatoc+''.join(area(a) for a in D['areas']),'areas.html'))
css="""@font-face{font-family:Golos;src:url('fonts/GolosText-variable.ttf')}*{box-sizing:border-box}:root{--red:#ed131c;--ink:#1c1c1c;--soft:#f4f4f6;--line:#dfe1e5}html{scroll-behavior:smooth}body{margin:0;background:white;color:var(--ink);font:15px/1.65 Golos,Arial,sans-serif}main{max-width:1000px;padding:36px 38px 80px;margin:auto}nav{position:sticky;top:0;background:#fffefef5;border-bottom:1px solid var(--line);display:flex;justify-content:center;gap:12px;padding:12px;z-index:1}nav a{padding:8px 16px;color:var(--ink);text-decoration:none;border-radius:7px}nav a[aria-current]{background:var(--ink);color:white}.skip{position:absolute;left:-9999px}.skip:focus{left:10px;background:white;z-index:4}.hero,header{background:var(--ink);color:white;border-bottom:4px solid var(--red);padding:28px 32px;border-radius:12px;margin-bottom:24px}h1{font-size:38px;line-height:1.15;margin:10px 0}h2{font-size:25px;line-height:1.3;margin:5px 0}h3{font-size:18px;line-height:1.4;margin:0 0 12px}small{font-size:13px}.lesson,.area{margin:40px 0 64px;scroll-margin-top:90px}.route{list-style:none;padding:0;margin:0}.step{display:grid;grid-template-columns:34px minmax(0,1fr);gap:16px;position:relative;margin:18px 0}.num{border:2px solid var(--red);border-radius:50%;height:32px;width:32px;display:grid;place-content:center;margin-top:20px;font-size:13px;background:white}.card{background:var(--soft);border-radius:14px;padding:22px 26px}.card p{margin:0 0 12px}.card p:last-child{margin:0}.check{padding-top:14px;border-top:1px solid var(--line)}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:white;border:1px solid var(--line);padding:14px;border-radius:7px;font:12px/1.6 Consolas,monospace}a{color:#a80008;text-underline-offset:3px}a:focus-visible,button:focus-visible{outline:3px solid var(--red);outline-offset:3px}.actions{display:flex;flex-wrap:wrap;gap:10px;margin:24px 0}.button{padding:11px 16px;background:var(--ink);border-radius:7px;color:white;text-decoration:none}.button:hover{background:#3c3c3c}.identity{display:grid;grid-template-columns:1fr 1fr;gap:25px;padding:4px 0 16px}.contents{padding:24px;background:var(--soft);border-radius:14px}.contents ol{columns:2;column-gap:30px}.contents li{break-inside:avoid;margin-bottom:6px}.provided,.refs{border-left:3px solid var(--red);padding:12px 18px;background:var(--soft)}.tag{display:inline-block;border:1px solid #606773;padding:2px 8px;border-radius:4px;font-size:12px;margin-bottom:12px}figure{margin:25px 0 35px 50px}figure img{max-width:100%;height:auto;border:1px solid var(--line)}figcaption{font-size:13px;color:#606773}header h2{color:white}@media(max-width:650px){main{padding:20px 14px}.hero,header{padding:22px}h1{font-size:30px}.card{padding:18px}.identity{grid-template-columns:1fr}.contents ol{columns:1}nav{position:static;padding:4px;gap:0}nav a{padding:10px;font-size:12px}.step{gap:9px;grid-template-columns:30px minmax(0,1fr)}figure{margin-left:0}}"""
(SITE/'assets/style.css').write_text(css,encoding='utf-8')
fontsrc=pathlib.Path(os.environ.get('PP11_FONT_DIR',str(R.parents[2]/'.codex/skills/subject-area-list/assets/fonts')))
if not fontsrc.exists():fontsrc=pathlib.Path.home()/'.codex/skills/subject-area-list/assets/fonts'
(SITE/'assets/fonts').mkdir(exist_ok=True)
for f in fontsrc.glob('*'):
 if f.suffix in ['.ttf','.txt']:shutil.copyfile(f,SITE/'assets/fonts'/f.name)
shots=SITE/'assets/screenshots';shots.mkdir(exist_ok=True)
for f in (R/'evidence').glob('*.png'):shutil.copyfile(f,shots/f.name)
def zipfiles(dest,files):
 with zipfile.ZipFile(DL/dest,'w',zipfile.ZIP_DEFLATED) as z:
  for p in sorted(set(files)):
   if p.is_file() and not any(x in p.parts for x in ['bin','obj','.inventory-qa','.git']) and p.name!='settings.local.json':z.write(p,p.relative_to(R).as_posix())
zipfiles('pm11-source.zip',list((R/'starter').rglob('*'))+list((R/'materials/variants').rglob('*'))+list((R/'materials/demo').rglob('*'))+list((R/'database').glob('*.sql')))
zipfiles('ShopDb-starter.zip',(R/'starter').rglob('*'))
zipfiles('ShopDb-demo.zip',(R/'app').rglob('*'))
zipfiles('pm11-migrations.zip',(R/'database').glob('*.sql'))
for f in (R/'app').glob('*'):
 if f.is_file() and f.suffix in ['.cs','.xaml','.csproj','.json'] and f.name!='settings.local.json':shutil.copyfile(f,DL/f.name)
for f in (R/'database').glob('*.sql'):shutil.copyfile(f,DL/f.name)
if (R/'forms/Форма отчёта ПП ПМ.11.docx').exists():shutil.copyfile(R/'forms/Форма отчёта ПП ПМ.11.docx',DL/'report-template.docx')

# PDFs use the user's portrait A4 profile and retain the card hierarchy.
FONT=pathlib.Path(os.environ.get('PP11_TNR_DIR','C:/Windows/Fonts'))
for name,f in [('TNR','times.ttf'),('TNRB','timesbd.ttf'),('Mono','consola.ttf')]:pdfmetrics.registerFont(TTFont(name,str(FONT/f)))
pdfmetrics.registerFontFamily('TNR',normal='TNR',bold='TNRB',italic='TNR',boldItalic='TNRB')
styles={
 'body':ParagraphStyle('body',fontName='TNR',fontSize=14,leading=21,alignment=TA_JUSTIFY,firstLineIndent=12.5*mm,spaceAfter=7,wordWrap='CJK'),
 'title':ParagraphStyle('title',fontName='TNRB',fontSize=16,leading=24,alignment=TA_CENTER,spaceBefore=8,spaceAfter=14,keepWithNext=True),
 'h2':ParagraphStyle('h2',fontName='TNRB',fontSize=14,leading=21,spaceBefore=8,spaceAfter=10,keepWithNext=True),
 'small':ParagraphStyle('small',fontName='TNR',fontSize=12,leading=16,spaceAfter=8,wordWrap='CJK'),
 'caption':ParagraphStyle('caption',fontName='TNR',fontSize=12,leading=14,alignment=TA_CENTER,spaceAfter=12),
 'toc':ParagraphStyle('toc',fontName='TNR',fontSize=12,leading=17,leftIndent=0,firstLineIndent=0,spaceBefore=4),
 'code':ParagraphStyle('code',fontName='Mono',fontSize=9.5,leading=13,spaceAfter=0)}
def para(text,style='body'):
 s=esc(text);s=re.sub(r'https?://[^\s<]+',lambda m:f'<link href="{m[0]}" color="#000000">{m[0]}</link>',s)
 return Paragraph(s.replace('\n','<br/>'),styles[style])
class PDF(BaseDocTemplate):
 def beforeDocument(self):self.context='';self.context_page=0
 def __init__(self,path,label):
  super().__init__(str(path),pagesize=A4,leftMargin=30*mm,rightMargin=20*mm,topMargin=20*mm,bottomMargin=20*mm,title=label,author='')
  self.label=label;frame=Frame(self.leftMargin,self.bottomMargin,self.width,self.height,id='body',leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)
  self.context='';self.context_page=0
  self.addPageTemplates(PageTemplate('main',frame,onPage=self.page_chrome,onPageEnd=self.running_context))
 def page_chrome(self,c,doc):
  c.setFillColor(colors.black);c.setFont('TNR',10);c.drawCentredString(A4[0]/2,10*mm,str(doc.page))
 def afterFlowable(self,f):
  if isinstance(f,Paragraph) and hasattr(f,'anchor'):
   self.context=f.getPlainText();self.context_page=self.page
   self.canv.bookmarkPage(f.anchor);self.canv.addOutlineEntry(f.getPlainText(),f.anchor,0,False)
   self.notify('TOCEntry',(0,f.getPlainText(),self.page,f.anchor))
 def running_context(self,c,doc):
  if self.context and self.context_page!=self.page:
   c.setFillColor(colors.black);c.setFont('TNR',10)
   title=self.context+' — продолжение'
   if pdfmetrics.stringWidth(title,'TNR',10)>self.width:title=self.context[:70]+'… — продолжение'
   c.drawString(self.leftMargin,A4[1]-14*mm,title)
def heading(title,anchor):
 p=para(title,'title');p.anchor=anchor;return p
def pdfcard(title,text,check='',extension=False):
 content=[para(('Расширение. ' if extension else '')+title,'h2')]+[para(x) for x in text.split('\n\n')]
 if check:content.append(para('Проверка. '+check))
 t=Table([[content]],colWidths=[160*mm]);t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,-1),colors.HexColor('#f4f4f6')),('BOX',(0,0),(-1,-1),.4,colors.HexColor('#dfe1e5')),('LINEBEFORE',(0,0),(0,-1),2,colors.HexColor('#ed131c')),('LEFTPADDING',(0,0),(-1,-1),10),('RIGHTPADDING',(0,0),(-1,-1),10),('TOPPADDING',(0,0),(-1,-1),8),('BOTTOMPADDING',(0,0),(-1,-1),8)]))
 return [t,Spacer(1,5*mm)]
def pdfblocks(blocks):
 global FIGURE_NUMBER
 out=[]
 for i,b in enumerate(blocks,1):
  if b['kind']=='code':
   lines=[]
   for line in codeof(b).splitlines():lines+=textwrap.wrap(line,width=80,replace_whitespace=False,drop_whitespace=False,break_long_words=True,break_on_hyphens=False) or ['']
   for off in range(0,len(lines),34):
    title=b['title']+(f' — продолжение {off//34+1}' if off else '')
    pre=Preformatted('\n'.join(lines[off:off+34]),styles['code'])
    out+=[KeepTogether([para(title,'h2'),pre]),Spacer(1,5*mm)]
  elif b['kind']=='image':
   f=imagefile(b)
   if f.exists():
    from PIL import Image as PILImage
    with PILImage.open(f) as im:w,h=im.size
    width=min(160*mm,w);height=width*h/w
    if height>150*mm:width*=150*mm/height;height=150*mm
    FIGURE_NUMBER+=1
    out.append(KeepTogether([Image(str(f),width,height),para(f'Рисунок {FIGURE_NUMBER} — '+b.get('title',''),'caption'),para(b.get('text',''),'small')]))
  else:out+=pdfcard(f'{i}. '+b['title'],b.get('text',''),b.get('check',''),b.get('extension',False))
 return out
def pdflinks():
 return pdfcard('Прямые ссылки на скачивание','Исходный комплект со всеми 30 областями:\n'+BASE+'downloads/pm11-source.zip\n\nЗавершённый демонстрационный образец для сверки:\n'+BASE+'downloads/ShopDb-demo.zip')
def make_pdf(kind):
 global FIGURE_NUMBER
 FIGURE_NUMBER=0
 label='Методические рекомендации ПП ПМ.11' if kind=='method' else 'Предметные области ПП ПМ.11'
 story=[para(label.upper(),'title'),para('Приложение с базой данных своей предметной области. Каталог, оформление и управление заказами.'),para('Образец «Пара» объясняет способ выполнения; собственные область и данные сохраняются.'),Spacer(1,10*mm),PageBreak(),para('СОДЕРЖАНИЕ','title')]
 toc=TableOfContents();toc.levelStyles=[styles['toc']];story+=[toc,PageBreak()]
 if kind=='method':
  for i,s in enumerate(D['assignment'],1):story+=[heading('1. '+s['title'],'assignment')]+pdfblocks(s['blocks'])
  for s in D['files']:story+=[heading('2. '+s['title'],'files')]+pdfblocks(s['blocks'])
  story+=pdflinks()
  for i,s in enumerate(D['guide'],1):
   blocks=copy.deepcopy(s['blocks'])
   if s.get('refs'):
    last=next(b for b in reversed(blocks) if b['kind']=='text')
    last['text']+='\n\nПодробное объяснение и код: справочник '+', '.join(map(str,s['refs']))+'.'
   story+=[heading(f'3.{i}. '+s['title'],f'step-{i}')]+pdfblocks(blocks)
  story+=[PageBreak(),heading('4. Подробный справочник образца','reference'),para('Сохранённые объяснения и код. Готовые вход, отбор и цена изучаются для интеграции; их повторная разработка не требуется. Специальные испытания повторов и конкуренции относятся к расширениям.'),para('Длинные листинги в PDF перенесены для чтения. Исполняемый текст брать из соответствующего файла исходного комплекта или демонстрационного архива; печатные переносы внутри строки не переносить в код. Пояснения и проверки каждого законченного объекта приведены рядом.')]
  for i,s in enumerate(D['reference'],1):
   story+=[heading(f'Справочник {i}. '+s['title'],f'ref-{i}')]
   if s.get('provided'):story+=pdfcard('Готовый компонент','Изучить устройство и проверить вызов на своих данных; повторное создание компонента не является отдельным заданием.')
   story+=pdfblocks(s['blocks'])
  story+=[heading('5. Литература','literature')]+[para(x) for x in D['literature']]
 else:
  story+=[heading('Начало работы с назначенной областью','start')]+pdfblocks(D['files'][0]['blocks'])+pdflinks()
  for a in D['areas']:
   story+=[PageBreak(),heading(a['title'],f'variant-{a["id"]}')]
   story+=pdfcard('С чего начать',a['start'])+pdfcard('Порядок и перенос образца',a['route']+'\n\n'+a['mapping'])
   story+=pdfblocks([b for b in a['blocks'] if b['title']!='Исходная точка и материалы'])
 path=DL/('assignment.pdf' if kind=='method' else 'guide.pdf');PDF(path,label).multiBuild(story)
 print(path.name)
make_pdf('method');make_pdf('areas')
manifest={'schema_version':1,'release':True,'files':{p.relative_to(SITE).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(SITE.rglob('*')) if p.is_file() and p.name!='manifest.json'}}
put('manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Student site, PDFs and archives built')

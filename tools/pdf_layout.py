"""Printable route-and-card layout shared by the two student PDFs."""
import html
import os
import copy
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Flowable, Frame, Image, KeepTogether, PageBreak,
    PageTemplate, Paragraph, Preformatted, Spacer, Table, TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents

INK = colors.HexColor('#1c1c1c')
RED = colors.HexColor('#ed131c')
SOFT = colors.HexColor('#f4f4f6')
LINE = colors.HexColor('#dfe1e5')
MUTED = colors.HexColor('#606773')
WIDTH = 160 * mm
STYLES = {}
FIGURE_NUMBER = 0


def register_fonts(root):
    from fontTools.ttLib import TTFont as Font
    from fontTools.varLib.instancer import instantiateVariableFont
    fonts = root / 'site/assets/fonts'
    for name, weight in [('Golos', 400), ('GolosSemi', 600), ('GolosBold', 700)]:
        target = fonts / f'{name}.ttf'
        with Font(fonts / 'GolosText-variable.ttf') as source:
            static = instantiateVariableFont(source, {'wght': weight}, inplace=False)
            static.recalcTimestamp = False
            # Give each static face a distinct PostScript name as well as weight.
            # ReportLab otherwise aliases all three faces to the regular font.
            for record in static['name'].names:
                value = {1: name, 2: 'Regular', 4: name, 6: name}.get(record.nameID)
                if value:
                    record.string = value.encode(record.getEncoding())
            static.save(target)
        pdfmetrics.registerFont(TTFont(name, str(target)))
    pdfmetrics.registerFontFamily('Golos', normal='Golos', bold='GolosBold',
                                  italic='Golos', boldItalic='GolosBold')
    pdfmetrics.registerFont(TTFont('Code', os.environ.get('PP11_MONO_FONT', 'C:/Windows/Fonts/consola.ttf')))
    STYLES.update({
        'body': ParagraphStyle('body', fontName='Golos', fontSize=10.5,
                               leading=16, textColor=INK, alignment=TA_LEFT,
                               spaceAfter=7, splitLongWords=True),
        'cardtitle': ParagraphStyle('cardtitle', fontName='GolosSemi', fontSize=13,
                                    leading=18, textColor=INK, spaceAfter=10),
        'hero': ParagraphStyle('hero', fontName='GolosBold', fontSize=24,
                               leading=28, textColor=colors.white, spaceAfter=12),
        'meta': ParagraphStyle('meta', fontName='GolosSemi', fontSize=9,
                               leading=13, textColor=colors.white, spaceAfter=16),
        'purpose': ParagraphStyle('purpose', fontName='Golos', fontSize=11,
                                  leading=17, textColor=colors.white),
        'small': ParagraphStyle('small', fontName='Golos', fontSize=9.5,
                                leading=15, textColor=MUTED, spaceAfter=8),
        'caption': ParagraphStyle('caption', fontName='Golos', fontSize=9.5,
                                  leading=15, textColor=MUTED, spaceAfter=10),
        'toc': ParagraphStyle('toc', fontName='Golos', fontSize=10,
                              leading=15, spaceBefore=6, textColor=INK),
        'code': ParagraphStyle('code', fontName='Code', fontSize=8.5,
                               leading=12, textColor=INK),
    })


def paragraph(text, style='body'):
    text = html.escape(str(text))
    if text.startswith('Проверка. '):
        text = '<b>Проверка.</b> ' + text[len('Проверка. '):]
    text = re.sub(r'https?://[^\s<]+',
                  lambda m: f'<link href="{m[0]}" color="#a80008">{m[0]}</link>', text)
    return Paragraph(text.replace('\n', '<br/>'), STYLES[style])


class Rule(Flowable):
    def __init__(self):
        super().__init__()
        self.height = 15

    def wrap(self, width, height):
        self.width = width
        return width, self.height

    def draw(self):
        self.canv.setStrokeColor(LINE)
        self.canv.setLineWidth(.6)
        self.canv.line(0, 9, self.width, 9)


class Hero(Flowable):
    keepWithNext = True

    def __init__(self, title, meta, purpose='', anchor=None):
        super().__init__()
        self.title = title
        self.anchor = anchor
        self.parts = [paragraph(meta, 'meta'), paragraph(title, 'hero')]
        if purpose:
            self.parts.append(paragraph(purpose, 'purpose'))

    def wrap(self, width, height):
        self.width = width
        self.sizes = [(p, p.wrap(width - 36, height)[1]) for p in self.parts]
        self.height = sum(h + p.getSpaceAfter() for p, h in self.sizes) + 35
        return width, self.height

    def draw(self):
        c = self.canv
        c.setFillColor(INK)
        c.rect(0, 0, self.width, self.height, stroke=0, fill=1)
        c.setFillColor(RED)
        c.rect(0, 0, self.width, 4, stroke=0, fill=1)
        y = self.height - 19
        for p, h in self.sizes:
            y -= h
            p.drawOn(c, 18, y)
            y -= p.getSpaceAfter()


class Card(Flowable):
    """One numbered route step; long steps split with an explicit continuation."""
    pad = 13
    gutter = 33
    spaceAfter = 13

    def __init__(self, number, title, parts, continued=False):
        super().__init__()
        self.number, self.title, self.parts = str(number), title, parts
        self.continued = continued
        self.head = paragraph(title + (' — продолжение' if continued else ''), 'cardtitle')

    def wrap(self, width, height):
        self.width = width
        self.inner = width - self.gutter - 2 * self.pad
        self.headheight = self.head.wrap(self.inner, 10000)[1]
        self.sizes = [(p, p.wrap(self.inner, 10000)[1]) for p in self.parts]
        self.height = 2 * self.pad + self.headheight + self.head.getSpaceAfter()
        self.height += sum(h + p.getSpaceAfter() for p, h in self.sizes)
        return width, self.height

    def split(self, width, height):
        self.wrap(width, height)
        if self.height < 400:
            return []
        available = height - 2 * self.pad - self.headheight - self.head.getSpaceAfter()
        if available < 65:
            return []
        first, rest = [], []
        for i, (part, ph) in enumerate(self.sizes):
            needed = ph + part.getSpaceAfter()
            if needed <= available + .01:
                first.append(part)
                available -= needed
                continue
            pieces = ([] if isinstance(part, Preformatted) else
                      part.split(self.inner, max(0, available - part.getSpaceAfter())))
            if len(pieces) >= 2:
                first.append(pieces[0])
                rest = pieces[1:] + self.parts[i + 1:]
            else:
                rest = self.parts[i:]
            break
        if not first or not rest:
            return []
        # Do not strand a separator at the bottom of a page.
        while first and isinstance(first[-1], Rule):
            rest.insert(0, first.pop())
        if not first:
            return []
        return [Card(self.number, self.title, first, self.continued),
                Card(self.number, self.title, rest, True)]

    def draw(self):
        c = self.canv
        x = self.gutter
        c.setFillColor(SOFT)
        c.roundRect(x, 0, self.width - x, self.height, 10, stroke=0, fill=1)
        cy = self.height - 24
        c.setStrokeColor(LINE)
        c.setLineWidth(.6)
        c.line(12, 0, 12, cy - 14)
        c.setFillColor(colors.white)
        c.setStrokeColor(RED)
        c.setLineWidth(1.1)
        c.circle(12, cy, 11, stroke=1, fill=1)
        c.setFillColor(INK)
        c.setFont('Golos', 9 if len(self.number) <= 2 else 7)
        c.drawCentredString(12, cy - 3, self.number)
        y = self.height - self.pad - self.headheight
        self.head.drawOn(c, x + self.pad, y)
        y -= self.head.getSpaceAfter()
        for part, ph in self.sizes:
            y -= ph
            part.drawOn(c, x + self.pad, y)
            y -= part.getSpaceAfter()


class Document(BaseDocTemplate):
    def __init__(self, path, label):
        super().__init__(str(path), pagesize=A4, leftMargin=30 * mm,
                         rightMargin=20 * mm, topMargin=20 * mm, bottomMargin=20 * mm,
                         title=label, author='')
        self.context = label
        self.context_page = 0
        self.addPageTemplates(PageTemplate('main', Frame(
            self.leftMargin, self.bottomMargin, self.width, self.height,
            leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0),
            onPageEnd=self.footer))

    def beforeDocument(self):
        self.context = 'Содержание'
        self.context_page = 0

    def afterFlowable(self, flowable):
        if isinstance(flowable, Hero) and flowable.anchor:
            self.context, self.context_page = flowable.title, self.page
            self.canv.bookmarkPage(flowable.anchor)
            self.canv.addOutlineEntry(flowable.title, flowable.anchor, 0, False)
            self.notify('TOCEntry', (0, flowable.title, self.page, flowable.anchor))

    def footer(self, canvas, doc):
        canvas.setFont('Golos', 8)
        canvas.setFillColor(MUTED)
        if self.page != self.context_page and self.page > 1:
            label = self.context + ' — продолжение'
            while pdfmetrics.stringWidth(label, 'Golos', 8) > self.width:
                label = label[:-17].rstrip('…') + '… — продолжение'
            canvas.drawString(self.leftMargin, A4[1] - 14 * mm, label)
        canvas.drawCentredString(A4[0] / 2, 10 * mm, str(self.page))


def card(number, title, text, check='', extension=False):
    parts = [paragraph(p) for p in text.split('\n\n') if p]
    if check:
        parts += [Rule(), paragraph('Проверка. ' + check)]
    return [Card(number, ('Расширение. ' if extension else '') + title, parts)]


def code_lines(text, width):
    """Wrap for display at the actual font width; never drop indentation or bytes."""
    lines = []
    for source in text.expandtabs(4).splitlines():
        group = []
        if not source:
            group.append('')
        while source:
            end = len(source)
            while pdfmetrics.stringWidth(source[:end], 'Code', 8.5) > width:
                end -= 1
            group.append(source[:end])
            source = source[end:]
        lines.append('\n'.join(group))
    return lines


def blocks(items, codeof, imagefile):
    global FIGURE_NUMBER
    result = []
    for index, b in enumerate(items, 1):
        if b['kind'] == 'code':
            lines = code_lines(codeof(b), WIDTH - Card.gutter - 2 * Card.pad)
            parts = [Preformatted(line or ' ', STYLES['code']) for line in lines]
            result += [Card(index, b['title'], parts)]
        elif b['kind'] == 'image':
            from PIL import Image as PILImage
            path = imagefile(b)
            if not path.exists():
                raise FileNotFoundError(path)
            with PILImage.open(path) as source:
                w, h = source.size
            w2 = min(WIDTH - 33, w)
            h2 = w2 * h / w
            if h2 > 350:
                w2 *= 350 / h2
                h2 = 350
            FIGURE_NUMBER += 1
            result += [KeepTogether([Image(str(path), w2, h2, hAlign='RIGHT'),
                         paragraph(f'Рисунок {FIGURE_NUMBER} — ' + b.get('title', ''), 'caption'),
                         paragraph(b.get('text', ''), 'small')])]
        else:
            result += card(index, b['title'], b.get('text', ''),
                           b.get('check', ''), b.get('extension', False))
    return result


def identity(left, right):
    def cell(text):
        label, body = text.split('\n', 1)
        return [Paragraph('<b>' + html.escape(label) + '</b>', STYLES['body']), paragraph(body)]
    t = Table([[cell(left), cell(right)]], colWidths=[WIDTH / 2] * 2)
    t.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (0, 0), 0), ('RIGHTPADDING', (0, 0), (0, 0), 16),
        ('LEFTPADDING', (1, 0), (1, 0), 16), ('RIGHTPADDING', (1, 0), (1, 0), 0),
        ('LINEBEFORE', (1, 0), (1, 0), .6, LINE),
        ('TOPPADDING', (0, 0), (-1, -1), 0),
    ]))
    return [t, Spacer(1, 18)]


def build_pdfs(root, data, codeof, imagefile):
    global FIGURE_NUMBER
    register_fonts(root)
    base = data['meta']['site_url']

    def links():
        return card('↓', 'Файлы для скачивания',
                    'Исходный комплект со всеми 30 областями:\n' + base +
                    'downloads/pm11-source.zip\n\n'
                    'Завершённый демонстрационный образец для сверки:\n' + base +
                    'downloads/ShopDb-demo.zip')

    for kind in ['method', 'areas']:
        FIGURE_NUMBER = 0
        label = 'Методические рекомендации' if kind == 'method' else 'Предметные области'
        story = [Hero(label, 'Производственная практика ПМ.11 · 7 семестр',
                      'Приложение с базой данных своей предметной области. '
                      'Каталог, оформление и управление заказами.'), Spacer(1, 20)]
        story += identity('Индивидуальная работа\nСохранить назначенные область, номер варианта '
                          'и собственные данные.',
                          'Образец «Пара»\nПоказывает способ выполнения. Контрольные значения '
                          'получать из своей БД.')
        story += [paragraph('Содержание', 'cardtitle')]
        toc = TableOfContents()
        toc.levelStyles = [STYLES['toc']]
        story += [toc, PageBreak()]

        def section(title, meta, anchor, purpose='', new_page=False):
            if new_page:
                story.append(PageBreak())
            gap = Spacer(1, 18)
            gap.keepWithNext = True
            story.extend([Hero(title, meta, purpose, anchor), gap])

        if kind == 'method':
            for s in data['assignment']:
                section(s['title'], 'ПП ПМ.11 · 1. Полное общее задание', 'assignment')
                story += blocks(s['blocks'], codeof, imagefile)
            for s in data['files']:
                section(s['title'], 'ПП ПМ.11 · 2. Файлы для работы', 'files', new_page=True)
                story += blocks(s['blocks'], codeof, imagefile)
            story += links()
            for index, s in enumerate(data['guide'], 1):
                section(s['title'], f'ПП ПМ.11 · 3. Разбор образца · Этап {index:02}',
                        f'step-{index}', new_page=True)
                stage_blocks = copy.deepcopy(s['blocks'])
                if s.get('refs'):
                    last_text = next(b for b in reversed(stage_blocks) if b['kind'] == 'text')
                    last_text['text'] += '\n\nПодробное объяснение и код: справочник ' + ', '.join(map(str, s['refs'])) + '.'
                story += blocks(stage_blocks, codeof, imagefile)
            section('Подробный справочник образца', 'ПП ПМ.11 · 4. Объяснения и код',
                    'reference', new_page=True)
            story += card('→', 'Как читать справочник',
                          'Сохранённые объяснения и код. Готовые вход, отбор и цена изучаются '
                          'для интеграции; их повторная разработка не требуется. Специальные '
                          'испытания повторов и конкуренции относятся к расширениям.\n\n'
                          'Длинные листинги в PDF перенесены для чтения. Исполняемый текст брать '
                          'из соответствующего файла исходного комплекта или демонстрационного '
                          'архива; печатные переносы внутри строки не переносить в код. '
                          'Пояснения и проверки каждого законченного объекта приведены рядом.')
            for index, s in enumerate(data['reference'], 1):
                section(s['title'], f'ПП ПМ.11 · Справочник {index:02}', f'ref-{index}')
                if s.get('provided'):
                    story += card('→', 'Готовый компонент', 'Изучить устройство и проверить вызов '
                                  'на своих данных; повторное создание компонента не является отдельным заданием.')
                story += blocks(s['blocks'], codeof, imagefile)
            section('Литература', 'ПП ПМ.11 · 5. Источники', 'literature', new_page=True)
            for index, text in enumerate(data['literature'], 1):
                story += card(index, 'Источник', text)
        else:
            section('Начало работы с назначенной областью', 'ПП ПМ.11 · Общий маршрут', 'start')
            story += blocks(data['files'][0]['blocks'], codeof, imagefile) + links()
            for a in data['areas']:
                section(a['title'], f'ПП ПМ.11 · Вариант {int(a["id"]):02}',
                        f'variant-{a["id"]}', new_page=True)
                story += identity('Индивидуальная работа\n' + a['subject'],
                                  'Образец «Пара»\nОбъясняет способ выполнения; '
                                  'его данные не заменяют данные назначенной области.')
                story += card(1, 'С чего начать', a['start'])
                story += card(2, 'Порядок и перенос образца', a['route'], a['mapping'])
                selected = [b for b in a['blocks'] if b['title'] != 'Исходная точка и материалы']
                for number, b in enumerate(selected, 3):
                    story += card(number, b['title'], b.get('text', ''), b.get('check', ''), b.get('extension', False))
        path = root / 'site/downloads' / ('assignment.pdf' if kind == 'method' else 'guide.pdf')
        Document(path, label + ' ПП ПМ.11').multiBuild(story)
        print(path.name)

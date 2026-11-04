import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.graphics.shapes import Drawing, Rect, Circle, Line, String, Group, Polygon

pdfmetrics.registerFont(TTFont('Nunito', 'Nunito-Regular.ttf'))
pdfmetrics.registerFont(TTFont('Nunito-Bold', 'Nunito-Bold.ttf'))

class RussianWorksheetCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(RussianWorksheetCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(RussianWorksheetCanvas, self).showPage()
        super(RussianWorksheetCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        page_w, page_h = A4
        # Top color accent bar (Warm burgundy-terracotta)
        self.setFillColor(colors.HexColor('#9A3412'))
        self.rect(26, page_h - 18, page_w - 52, 3, fill=True, stroke=False)
        
        # Bottom footer bar
        self.setFillColor(colors.HexColor('#E7E5E4'))
        self.rect(26, 20, page_w - 52, 1, fill=True, stroke=False)
        self.setFont('Nunito-Bold', 7.5)
        self.setFillColor(colors.HexColor('#9A3412'))
        self.drawString(26, 12, "РУССКИЙ ЯЗЫК • 2 КЛАСС • ЛИСТ ЗАКРЕПЛЕНИЯ ЗНАНИЙ")
        self.setFont('Nunito', 7.5)
        self.setFillColor(colors.HexColor('#78716C'))
        self.drawRightString(page_w - 26, 12, f"Страница {self._pageNumber} из {page_count}")
        self.restoreState()

def create_fox_self_check():
    """Drawing of 11 fox paws/stars for self-assessment"""
    d = Drawing(540, 24)
    d.add(Rect(0, 0, 540, 24, rx=4, ry=4, fillColor=colors.HexColor('#FFFBEB'), strokeColor=colors.HexColor('#FDE68A'), strokeWidth=1))
    d.add(String(8, 8, "🦊 Самооценка: закрась след Лисички за каждое верное задание:", fontName='Nunito-Bold', fontSize=7.5, fillColor=colors.HexColor('#9A3412')))
    
    start_x = 280
    for i in range(11):
        x = start_x + i * 16
        # Small circle paw
        d.add(Circle(x + 5, 11, 4.5, fillColor=colors.HexColor('#FFFFFF'), strokeColor=colors.HexColor('#EA580C'), strokeWidth=0.8))
        d.add(Circle(x + 2, 17, 1.2, fillColor=colors.HexColor('#EA580C'), strokeColor=None))
        d.add(Circle(x + 5, 18, 1.2, fillColor=colors.HexColor('#EA580C'), strokeColor=None))
        d.add(Circle(x + 8, 17, 1.2, fillColor=colors.HexColor('#EA580C'), strokeColor=None))
        d.add(String(x + 3.2, 8, str(i + 1), fontName='Nunito', fontSize=5, fillColor=colors.HexColor('#9A3412')))
        
    d.add(String(485, 8, "[ ___ / 11 ]", fontName='Nunito-Bold', fontSize=7.5, fillColor=colors.HexColor('#C2410C')))
    return d

def build_russian_worksheet_pdf(output_path):
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        leftMargin=26,
        rightMargin=26,
        topMargin=22,
        bottomMargin=22
    )

    styles = getSampleStyleSheet()

    task_num = ParagraphStyle(
        'TaskNum',
        fontName='Nunito-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor('#9A3412'),
        spaceBefore=3.5,
        spaceAfter=1.5
    )
    task_body = ParagraphStyle(
        'TaskBody',
        fontName='Nunito',
        fontSize=7.8,
        leading=10.5,
        textColor=colors.HexColor('#1C1917'),
        spaceAfter=2
    )
    task_math = ParagraphStyle(
        'TaskMath',
        fontName='Nunito-Bold',
        fontSize=8,
        leading=11,
        textColor=colors.HexColor('#0C0A09'),
        alignment=1
    )
    key_style = ParagraphStyle(
        'KeyStyle',
        fontName='Nunito',
        fontSize=6.5,
        leading=8.5,
        textColor=colors.HexColor('#57534E')
    )

    story = []

    # ==================== PAGE 1 ====================
    # Title & Student Fields Table
    header_table_data = [
        [
            Paragraph("<b>РУССКИЙ ЯЗЫК • 2 КЛАСС</b><br/>Лист заданий: «Что такое окончание. Закрепление» (по Н. А. Костину)", ParagraphStyle('WH', fontName='Nunito-Bold', fontSize=10, leading=12.5, textColor=colors.HexColor('#431407'))),
            Paragraph("<b>Фамилия, имя:</b> ___________________________<br/><b>Класс:</b> 2 «____» &nbsp;&nbsp;&nbsp;&nbsp; <b>Дата:</b> _______________", ParagraphStyle('WF', fontName='Nunito', fontSize=8, leading=11, textColor=colors.HexColor('#1C1917')))
        ]
    ]
    t_head = Table(header_table_data, colWidths=[310, 230])
    t_head.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FFFBEB')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#FDE68A')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_head)
    story.append(Spacer(1, 3))

    # Row 1: Task 1 and Task 2 side by side
    t1_text = """<b>Упражнение 1. Корень слова и «лишнее» слово</b><br/>
    Выделите корень дугой во всех родственных словах. Найдите и зачеркните лишнее слово-ловушку:<br/>
    а) <i>Вода, водный, водяной, <s>водить</s>, подводник.</i><br/>
    б) <i>Кормить, кормушка, корм, корка, накормил.</i><br/>
    <i>Лишнее слово в ряду (б):</i> ________________________
    """
    t2_text = """<b>Упражнение 2. Родственные слова или формы?</b><br/>
    Распределите слова по группам (соедините стрелками):<br/>
    • <b>Родственные слова:</b> <i>лес, лесной, лесник, лесок</i><br/>
    • <b>Формы одного слова:</b> <i>лес, леса, лесу, лесом, о лесе</i><br/>
    <i>Запомни:</i> формы слова называют <b>один и тот же</b> предмет!
    """
    t1_2_table = Table([[Paragraph(t1_text, task_body), Paragraph(t2_text, task_body)]], colWidths=[270, 270])
    t1_2_table.setStyle(TableStyle([
        ('BOX', (0,0), (0,0), 0.7, colors.HexColor('#FED7AA')),
        ('BOX', (1,0), (1,0), 0.7, colors.HexColor('#FED7AA')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FAFAF9')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t1_2_table)
    story.append(Spacer(1, 3))

    # Task 3: Change word by questions
    t3_text = """<b>Упражнение 3. Изменение слова по вопросам (наблюдение Костина)</b><br/>
    Измените слово <b>лиса</b> по вопросам. Подчеркните изменяемую часть слова на конце (окончание):<br/>
    • (Кто?) бежит рыжая <b>лис<u>а</u></b>. &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • (К кому?) подошёл к <b>лис</b>[ &nbsp;&nbsp; ].<br/>
    • (Кого?) заметили в кустах <b>лис</b>[ &nbsp;&nbsp; ]. &nbsp;&nbsp;&nbsp;&nbsp; • (Кем?) любуемся хитрой <b>лис</b>[ &nbsp;&nbsp; ].<br/>
    • (О ком?) сказка о <b>лис</b>[ &nbsp;&nbsp; ].
    """
    t3_table = Table([[Paragraph(t3_text, task_body)]], colWidths=[540])
    t3_table.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.7, colors.HexColor('#BAE6FD')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F0F9FF')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t3_table)
    story.append(Spacer(1, 3))

    # Task 4 & Task 5 side by side
    t4_text = """<b>Упражнение 4. Основа и окончание</b><br/>
    Выделите основу скобками <b>[ &nbsp; ]</b>, а окончание подчеркните <b><u> &nbsp; </u></b> по образцу Костина:<br/>
    <i>Образец: [книг]<u>а</u>, [стол]□.</i><br/>
    • парт[ &nbsp; ] &nbsp;&nbsp;&nbsp; • окн[ &nbsp; ] &nbsp;&nbsp;&nbsp; • зим[ &nbsp; ]<br/>
    • дуб[ &nbsp; ] &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • школ[ &nbsp; ] &nbsp;&nbsp;&nbsp; • мороз[ &nbsp; ]
    """
    t5_text = """<b>Упражнение 5. «Ловушка: суффикс или окончание?»</b><br/>
    Измените прилагательное по родам и числам, чтобы найти истинное окончание:<br/>
    • морозн-<b>ый</b> ➔ морозн-<b>ая</b> ➔ морозн-<b>ое</b> ➔ морозн-<b>ые</b><br/>
    <i>Вывод:</i> буква <b>н</b> — суффикс! Окончание: <b>-ый</b>.<br/>
    • зимн-<b>ий</b> ➔ зимн-<b>[ &nbsp;&nbsp; ]</b> ➔ зимн-<b>[ &nbsp;&nbsp; ]</b>. Окончание: <b>[ &nbsp;&nbsp; ]</b>.
    """
    t4_5_table = Table([[Paragraph(t4_text, task_body), Paragraph(t5_text, task_body)]], colWidths=[270, 270])
    t4_5_table.setStyle(TableStyle([
        ('BOX', (0,0), (0,0), 0.7, colors.HexColor('#CBD5E1')),
        ('BOX', (1,0), (1,0), 0.7, colors.HexColor('#FECDD3')),
        ('BACKGROUND', (0,0), (0,0), colors.HexColor('#F8FAFC')),
        ('BACKGROUND', (1,0), (1,0), colors.HexColor('#FFF1F2')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t4_5_table)
    story.append(Spacer(1, 3))

    # Task 6: Word combinations
    t6_text = """<b>Упражнение 6. Выбор окончания для связи слов в словосочетании</b><br/>
    Вставьте правильное окончание, чтобы слова подружились:<br/>
    • русск<b>[ &nbsp;&nbsp; ]</b> берёза (<i>-ая, -ое, -ий</i>) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • могуч<b>[ &nbsp;&nbsp; ]</b> дуб (<i>-ая, -ий, -ее</i>)<br/>
    • ярк<b>[ &nbsp;&nbsp; ]</b> солнце (<i>-ое, -ая, -ие</i>) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • бел<b>[ &nbsp;&nbsp; ]</b> хлопья снега (<i>-ые, -ая, -ое</i>)
    """
    t6_table = Table([[Paragraph(t6_text, task_body)]], colWidths=[540])
    t6_table.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.7, colors.HexColor('#D1D5DB')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FFFFFF')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t6_table)

    # ==================== PAGE 2 ====================
    story.append(PageBreak())

    # Page 2 Subheader
    p2_head = [
        [
            Paragraph("<b>СТРАНИЦА 2 • СВЯЗЬ СЛОВ В ПРЕДЛОЖЕНИИ И ПРАКТИЧЕСКИЙ РАЗБОР</b>", ParagraphStyle('P2H', fontName='Nunito-Bold', fontSize=9, textColor=colors.HexColor('#9A3412'))),
            Paragraph("Окончание связывает слова по смыслу в предложении!", ParagraphStyle('P2R', fontName='Nunito', fontSize=7.5, textColor=colors.HexColor('#78716C'), alignment=2))
        ]
    ]
    t_p2_head = Table(p2_head, colWidths=[310, 230])
    t_p2_head.setStyle(TableStyle([
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('TOPPADDING', (0,0), (-1,-1), 0),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 0),
    ]))
    story.append(t_p2_head)
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#F97316'), spaceAfter=3))

    # Task 7: Deformed sentences (Words quarrelled)
    t7_text = """<b>Упражнение 7. «Слова поссорились — помири их!»</b><br/>
    Раскройте скобки, изменив окончания слов так, чтобы получилось правильное предложение:<br/>
    <i>На (вырубка) растут (молодая) (осинка). В (нора) сидит пушистая лисица.</i><br/>
    <i>Запишите составленные предложения:</i><br/>
    1) ____________________________________________________________________________________<br/>
    2) ____________________________________________________________________________________
    """
    t7_table = Table([[Paragraph(t7_text, task_body)]], colWidths=[540])
    t7_table.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.7, colors.HexColor('#FED7AA')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FFFBEB')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t7_table)
    story.append(Spacer(1, 3))

    # Task 8 & Task 9 side by side
    t8_text = """<b>Упражнение 8. «Ошибки Хитрой Лисы»</b><br/>
    Лиса неверно выделила окончания. Зачеркните лишние буквы и выделите правильно:<br/>
    1) берез-<b><u>за</u></b> ➔ берез-<b><u>а</u></b> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 2) книг-<b><u>га</u></b> ➔ ____________<br/>
    3) зимн-<b><u>ний</u></b> ➔ __________ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 4) сосн-<b><u>ны</u></b> ➔ ___________
    """
    t9_text = """<b>Упражнение 9. «Найди нулевое окончание»</b><br/>
    Обведи слова с нулевым окончанием <b>[ &nbsp; ]□</b>:<br/>
    <i>Мороз, река, дуб, поляна, лес, окно, кот, звезда.</i><br/>
    <i>Докажи:</i> мороз ➔ мороз<b>а</b>, дуб ➔ дуб<b>а</b>, лес ➔ лес<b>а</b>!
    """
    t8_9_table = Table([[Paragraph(t8_text, task_body), Paragraph(t9_text, task_body)]], colWidths=[270, 270])
    t8_9_table.setStyle(TableStyle([
        ('BOX', (0,0), (0,0), 0.7, colors.HexColor('#FECDD3')),
        ('BOX', (1,0), (1,0), 0.7, colors.HexColor('#BAE6FD')),
        ('BACKGROUND', (0,0), (0,0), colors.HexColor('#FFF1F2')),
        ('BACKGROUND', (1,0), (1,0), colors.HexColor('#F0F9FF')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t8_9_table)
    story.append(Spacer(1, 3))

    # Task 10: Copying with task
    t10_text = """<b>Упражнение 10. Списывание с грамматическим заданием по Костину</b><br/>
    Спишите текст. В каждом слове подчеркните окончание (в словах с нулевым окончанием поставьте значок □):<br/>
    <i>Зимнее солнце ярко осветило снежную поляну.</i><br/>
    ________________________________________________________________________________________<br/>
    ________________________________________________________________________________________
    """
    t10_table = Table([[Paragraph(t10_text, task_body)]], colWidths=[540])
    t10_table.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.7, colors.HexColor('#CBD5E1')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t10_table)
    story.append(Spacer(1, 3))

    # Task 11: Star task
    t11_text = """<b>⭐ Упражнение 11. Рассуждение-доказательство по Костину (со звёздочкой)</b><br/>
    Докажите, почему в паре <b>дуб — дубы</b> перед нами формы одного слова, а в паре <b>дуб — дубовый</b> — разные родственные слова?<br/>
    <i>Доказательство:</i> __________________________________________________________________________________<br/>
    ____________________________________________________________________________________________________
    """
    t11_table = Table([[Paragraph(t11_text, task_body)]], colWidths=[540])
    t11_table.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.7, colors.HexColor('#FDE047')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FEFCE8')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t11_table)
    story.append(Spacer(1, 3))

    # Self check fox paws
    story.append(create_fox_self_check())
    story.append(Spacer(1, 3))

    # Teacher key
    key_text = """<b>🔑 Ответы и методические ключи для учителя:</b><br/>
    <b>Упр.1:</b> а) вод- (лишнее водить); б) корм- (лишнее корка). | <b>Упр.2:</b> Родственные: лес, лесной, лесник, лесок. Формы слова: лес, леса, лесу, лесом, о лесе. | <b>Упр.3:</b> лис-у, лис-у, лис-ой, о лис-е (окончания: -а, -у, -у, -ой, -е). | <b>Упр.4:</b> парт-а, окн-о, зим-а, дуб-□, школ-а, мороз-□. | <b>Упр.5:</b> зимн-яя, зимн-ее, окончание -ий. | <b>Упр.6:</b> русск-ая, могуч-ий, ярк-ое, бел-ые. | <b>Упр.7:</b> 1) На вырубке растут молодые осинки. 2) В норе сидит пушистая лисица. | <b>Упр.8:</b> книг-а, зимн-ий, сосн-ы. | <b>Упр.9:</b> мороз□, дуб□, лес□, кот□. | <b>Упр.10:</b> Зимн-ее, солнц-е, ярк-о (наречие без оконч.), освет-ило, снежн-ую, полян-у. | <b>Упр.11:</b> Дуб и дубы называют один и тот же предмет (один и много). Дуб и дубовый называют предмет и его признак, корень один, но слова разные родственные.
    """
    t_key = Table([[Paragraph(key_text, key_style)]], colWidths=[540])
    t_key.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor('#D6D3D1')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FAFAF9')),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_key)

    doc.build(story, canvasmaker=RussianWorksheetCanvas)
    print(f"Built {output_path} successfully!")

if __name__ == '__main__':
    out_dir = 'materials_2grade_russian_ending'
    os.makedirs(out_dir, exist_ok=True)
    build_russian_worksheet_pdf(os.path.join(out_dir, '2_List_zadaniy_Kostin_Okonchanie_2klass.pdf'))

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

class WorksheetCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(WorksheetCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(WorksheetCanvas, self).showPage()
        super(WorksheetCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        page_w, page_h = A4
        # Top color accent bar
        self.setFillColor(colors.HexColor('#0284C7')) # Bright cyan-blue
        self.rect(28, page_h - 18, page_w - 56, 3, fill=True, stroke=False)
        
        # Bottom footer bar
        self.setFillColor(colors.HexColor('#E2E8F0'))
        self.rect(28, 20, page_w - 56, 1, fill=True, stroke=False)
        self.setFont('Nunito-Bold', 7.5)
        self.setFillColor(colors.HexColor('#0284C7'))
        self.drawString(28, 12, "РАБОЧИЙ ЛИСТ ПО МАТЕМАТИКЕ • 1 КЛАСС")
        self.setFont('Nunito', 7.5)
        self.setFillColor(colors.HexColor('#64748B'))
        self.drawRightString(page_w - 28, 12, f"Страница {self._pageNumber} из {page_count}")
        self.restoreState()

def create_bundle_drawing():
    """Drawing of 10 sticks bundled with ribbon + 4 loose sticks with completion arc"""
    d = Drawing(460, 42)
    # Background card
    d.add(Rect(0, 0, 460, 42, rx=6, ry=6, fillColor=colors.HexColor('#F0F9FF'), strokeColor=colors.HexColor('#BAE6FD'), strokeWidth=1))
    
    # Left group: 9 loose sticks
    d.add(String(12, 28, "Слева 9 палочек:", fontName='Nunito-Bold', fontSize=8, fillColor=colors.HexColor('#0369A1')))
    for i in range(9):
        x = 14 + i * 8
        d.add(Line(x, 6, x, 24, strokeColor=colors.HexColor('#D97706'), strokeWidth=2))
        d.add(Circle(x, 24, 1.2, fillColor=colors.HexColor('#B45309'), strokeColor=colors.HexColor('#B45309')))
    
    # Arrow showing 1 stick moved from right to left
    d.add(String(92, 14, "+1 ➔", fontName='Nunito-Bold', fontSize=9, fillColor=colors.HexColor('#DC2626')))
    
    # Middle: The 10-bundle tied with ribbon
    d.add(Rect(122, 5, 48, 22, rx=3, ry=3, fillColor=colors.HexColor('#FEF3C7'), strokeColor=colors.HexColor('#F59E0B'), strokeWidth=1))
    # Bundle sticks
    for i in range(10):
        x = 126 + i * 4.2
        d.add(Line(x, 6, x, 25, strokeColor=colors.HexColor('#B45309'), strokeWidth=1.5))
    # Blue ribbon in middle
    d.add(Rect(122, 13, 48, 6, fillColor=colors.HexColor('#2563EB'), strokeColor=colors.HexColor('#1D4ED8'), strokeWidth=0.5))
    d.add(String(125, 29, "= 1 ДЕСЯТОК (10)", fontName='Nunito-Bold', fontSize=7.5, fillColor=colors.HexColor('#B45309')))
    
    # Right group: 3 remaining loose sticks
    d.add(String(182, 14, "+", fontName='Nunito-Bold', fontSize=10, fillColor=colors.HexColor('#0369A1')))
    d.add(String(198, 28, "Остаток 3:", fontName='Nunito-Bold', fontSize=8, fillColor=colors.HexColor('#0369A1')))
    for i in range(3):
        x = 202 + i * 8
        d.add(Line(x, 6, x, 24, strokeColor=colors.HexColor('#D97706'), strokeWidth=2))
    
    # Result formula
    d.add(Rect(240, 6, 210, 30, rx=4, ry=4, fillColor=colors.HexColor('#FFFFFF'), strokeColor=colors.HexColor('#38BDF8'), strokeWidth=1))
    d.add(String(248, 21, "9 + 4 = 9 + (1 + 3) = 10 + 3 = 13", fontName='Nunito-Bold', fontSize=9.5, fillColor=colors.HexColor('#0C4A6E')))
    d.add(String(248, 9, "Сначала дополняем до 10, затем прибавляем остаток!", fontName='Nunito', fontSize=6.5, fillColor=colors.HexColor('#0284C7')))
    
    return d

def create_stepping_stones_drawing():
    """Drawing of stepping stones (цепочка вычислений по кочкам)"""
    d = Drawing(460, 36)
    d.add(Rect(0, 0, 460, 36, rx=6, ry=6, fillColor=colors.HexColor('#F8FAFC'), strokeColor=colors.HexColor('#E2E8F0'), strokeWidth=1))
    
    # Start: Rabbit icon representation / label
    d.add(String(8, 14, "🐰 Старт:", fontName='Nunito-Bold', fontSize=9, fillColor=colors.HexColor('#475569')))
    
    steps = [
        ("9", 60),
        ("12", 145),
        ("7", 230),
        ("15", 315),
        ("5", 400)
    ]
    ops = [
        ("+ 3", 102),
        ("− 5", 187),
        ("+ 8", 272),
        ("− 10", 357)
    ]
    
    # Draw stones
    for i, (val, x) in enumerate(steps):
        # Stone circle
        is_first = (i == 0)
        bg = colors.HexColor('#38BDF8') if is_first else colors.HexColor('#FFFFFF')
        border = colors.HexColor('#0284C7')
        d.add(Circle(x, 18, 14, fillColor=bg, strokeColor=border, strokeWidth=1.5))
        if is_first:
            d.add(String(x - 4, 13, val, fontName='Nunito-Bold', fontSize=10, fillColor=colors.white))
        else:
            # Empty line for student to write answer
            d.add(Line(x - 7, 12, x + 7, 12, strokeColor=colors.HexColor('#94A3B8'), strokeWidth=1))
            
    # Draw jump arrows
    for op, x in ops:
        d.add(Line(x - 16, 18, x + 16, 18, strokeColor=colors.HexColor('#0284C7'), strokeWidth=1.2))
        d.add(Polygon([x + 16, 18, x + 11, 21, x + 11, 15], fillColor=colors.HexColor('#0284C7'), strokeColor=None))
        d.add(String(x - 9, 23, op, fontName='Nunito-Bold', fontSize=8, fillColor=colors.HexColor('#0369A1')))
        
    return d

def create_carrots_self_check():
    """Drawing of 13 carrots for self-assessment"""
    d = Drawing(460, 24)
    d.add(Rect(0, 0, 460, 24, rx=4, ry=4, fillColor=colors.HexColor('#FFF7ED'), strokeColor=colors.HexColor('#FDBA74'), strokeWidth=1))
    d.add(String(8, 8, "🥕 Самооценка: закрась морковку за верное задание:", fontName='Nunito-Bold', fontSize=7.5, fillColor=colors.HexColor('#C2410C')))
    
    # 13 carrot outlines
    start_x = 230
    for i in range(13):
        x = start_x + i * 14
        # Carrot triangle
        d.add(Polygon([x, 4, x + 8, 4, x + 4, 16], fillColor=colors.HexColor('#FFFFFF'), strokeColor=colors.HexColor('#EA580C'), strokeWidth=1))
        # Leaf
        d.add(Line(x + 4, 16, x + 2, 20, strokeColor=colors.HexColor('#16A34A'), strokeWidth=1))
        d.add(Line(x + 4, 16, x + 6, 20, strokeColor=colors.HexColor('#16A34A'), strokeWidth=1))
        # Small number
        d.add(String(x + 1.5, 6, str(i + 1), fontName='Nunito', fontSize=5, fillColor=colors.HexColor('#9A3412')))
        
    d.add(String(416, 8, "[ ___ / 13 ]", fontName='Nunito-Bold', fontSize=7.5, fillColor=colors.HexColor('#EA580C')))
    return d

def build_worksheet_pdf(output_path):
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        leftMargin=26,
        rightMargin=26,
        topMargin=22,
        bottomMargin=22
    )

    styles = getSampleStyleSheet()

    header_title = ParagraphStyle(
        'WsHeader',
        fontName='Nunito-Bold',
        fontSize=13,
        leading=16,
        textColor=colors.HexColor('#0F172A'),
        alignment=1,
        spaceAfter=2
    )
    header_sub = ParagraphStyle(
        'WsSub',
        fontName='Nunito-Bold',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#0284C7'),
        alignment=1,
        spaceAfter=6
    )
    task_num = ParagraphStyle(
        'TaskNum',
        fontName='Nunito-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor('#0369A1'),
        spaceBefore=4,
        spaceAfter=2
    )
    task_body = ParagraphStyle(
        'TaskBody',
        fontName='Nunito',
        fontSize=8,
        leading=11,
        textColor=colors.HexColor('#1E293B'),
        spaceAfter=2
    )
    task_math = ParagraphStyle(
        'TaskMath',
        fontName='Nunito-Bold',
        fontSize=8.5,
        leading=11.5,
        textColor=colors.HexColor('#0F172A'),
        alignment=1
    )
    key_style = ParagraphStyle(
        'KeyStyle',
        fontName='Nunito',
        fontSize=6.5,
        leading=8.5,
        textColor=colors.HexColor('#64748B')
    )

    story = []

    # ==================== PAGE 1 ====================
    # Title & Student Fields Table
    header_table_data = [
        [
            Paragraph("<b>МАТЕМАТИКА • 1 КЛАСС</b><br/>Рабочий лист: «Сложение и вычитание с переходом через десяток»", ParagraphStyle('WH', fontName='Nunito-Bold', fontSize=10.5, leading=13, textColor=colors.HexColor('#0C4A6E'))),
            Paragraph("<b>Фамилия, имя:</b> ___________________________<br/><b>Класс:</b> 1 «____» &nbsp;&nbsp;&nbsp;&nbsp; <b>Дата:</b> _______________", ParagraphStyle('WF', fontName='Nunito', fontSize=8.5, leading=12, textColor=colors.HexColor('#1E293B')))
        ]
    ]
    t_head = Table(header_table_data, colWidths=[310, 230])
    t_head.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F0F9FF')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#7DD3FC')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_head)
    story.append(Spacer(1, 4))

    # Row 1: Task 1 and Task 2 side by side
    t1_text = """<b>Задание 1. Разрядный состав чисел 11–20</b><br/>Заполни таблицу и пропуски:<br/>
    • 1 дес. 4 ед. = <b>[ &nbsp;&nbsp;&nbsp; ]</b> &nbsp;&nbsp;&nbsp; • 1 дес. 7 ед. = <b>[ &nbsp;&nbsp;&nbsp; ]</b><br/>
    • 16 = <b>[ &nbsp;&nbsp;&nbsp; ]</b> дес. <b>[ &nbsp;&nbsp;&nbsp; ]</b> ед.<br/>
    • 19 = <b>[ &nbsp;&nbsp;&nbsp; ]</b> дес. <b>[ &nbsp;&nbsp;&nbsp; ]</b> ед.
    """
    t2_text = """<b>Задание 2. Разминка: «Дополни до 10!»</b><br/>
    9 + <b>[ &nbsp; ]</b> = 10 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 8 + <b>[ &nbsp; ]</b> = 10<br/>
    7 + <b>[ &nbsp; ]</b> = 10 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 6 + <b>[ &nbsp; ]</b> = 10<br/>
    5 + <b>[ &nbsp; ]</b> = 10 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 9 + <b>[ &nbsp; ]</b> = 10
    """
    t1_2_table = Table([[Paragraph(t1_text, task_body), Paragraph(t2_text, task_body)]], colWidths=[270, 270])
    t1_2_table.setStyle(TableStyle([
        ('BOX', (0,0), (0,0), 0.8, colors.HexColor('#BAE6FD')),
        ('BOX', (1,0), (1,0), 0.8, colors.HexColor('#BAE6FD')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t1_2_table)
    story.append(Spacer(1, 4))

    # Task 3: Bundle of sticks visual
    story.append(Paragraph("<b>Задание 3. Наглядная модель: как палочки помогают сложить 9 + 4</b>", task_num))
    story.append(create_bundle_drawing())
    story.append(Spacer(1, 4))

    # Task 4: Addition with split boxes
    story.append(Paragraph("<b>Задание 4. Сложение по частям (дополни до 10, затем прибавь остаток):</b>", task_num))
    t4_data = [
        [
            Paragraph("<i>Образец:</i><br/>9 + 4 = 9 + (1 + 3) = 10 + 3 = <b>13</b>", task_body),
            Paragraph("8 + 5 = 8 + (<b>[ &nbsp; ]</b> + <b>[ &nbsp; ]</b>) = 10 + <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", task_body),
        ],
        [
            Paragraph("9 + 5 = 9 + (<b>[ &nbsp; ]</b> + <b>[ &nbsp; ]</b>) = 10 + <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", task_body),
            Paragraph("7 + 5 = 7 + (<b>[ &nbsp; ]</b> + <b>[ &nbsp; ]</b>) = 10 + <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", task_body),
        ],
        [
            Paragraph("8 + 4 = 8 + (<b>[ &nbsp; ]</b> + <b>[ &nbsp; ]</b>) = 10 + <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", task_body),
            Paragraph("9 + 6 = 9 + (<b>[ &nbsp; ]</b> + <b>[ &nbsp; ]</b>) = 10 + <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", task_body),
        ]
    ]
    t4_table = Table(t4_data, colWidths=[270, 270])
    t4_table.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E2E8F0')),
        ('BACKGROUND', (0,0), (0,0), colors.HexColor('#EFF6FF')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t4_table)
    story.append(Spacer(1, 4))

    # Task 5: Subtraction by parts with boxes
    story.append(Paragraph("<b>Задание 5. Вычитание по частям (уменьши до 10, затем вычти остаток):</b>", task_num))
    t5_data = [
        [
            Paragraph("<i>Образец:</i><br/>12 − 4 = (12 − 2) − 2 = 10 − 2 = <b>8</b>", task_body),
            Paragraph("14 − 6 = (14 − <b>[ &nbsp; ]</b>) − <b>[ &nbsp; ]</b> = 10 − <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", task_body),
        ],
        [
            Paragraph("13 − 5 = (13 − <b>[ &nbsp; ]</b>) − <b>[ &nbsp; ]</b> = 10 − <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", task_body),
            Paragraph("11 − 4 = (11 − <b>[ &nbsp; ]</b>) − <b>[ &nbsp; ]</b> = 10 − <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", task_body),
        ],
        [
            Paragraph("15 − 7 = (15 − <b>[ &nbsp; ]</b>) − <b>[ &nbsp; ]</b> = 10 − <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", task_body),
            Paragraph("12 − 5 = (12 − <b>[ &nbsp; ]</b>) − <b>[ &nbsp; ]</b> = 10 − <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", task_body),
        ]
    ]
    t5_table = Table(t5_data, colWidths=[270, 270])
    t5_table.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E2E8F0')),
        ('BACKGROUND', (0,0), (0,0), colors.HexColor('#FFF1F2')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t5_table)
    story.append(Spacer(1, 4))

    # Task 6: Speed columns
    story.append(Paragraph("<b>Задание 6. Счётный марафон Зайчика (реши быстро и без ошибок):</b>", task_num))
    t6_data = [
        [
            Paragraph("9 + 3 = <b>[ &nbsp;&nbsp; ]</b>", task_math),
            Paragraph("11 − 3 = <b>[ &nbsp;&nbsp; ]</b>", task_math),
            Paragraph("8 + 6 = <b>[ &nbsp;&nbsp; ]</b>", task_math),
            Paragraph("13 − 4 = <b>[ &nbsp;&nbsp; ]</b>", task_math),
        ],
        [
            Paragraph("8 + 3 = <b>[ &nbsp;&nbsp; ]</b>", task_math),
            Paragraph("12 − 5 = <b>[ &nbsp;&nbsp; ]</b>", task_math),
            Paragraph("9 + 7 = <b>[ &nbsp;&nbsp; ]</b>", task_math),
            Paragraph("14 − 5 = <b>[ &nbsp;&nbsp; ]</b>", task_math),
        ]
    ]
    t6_table = Table(t6_data, colWidths=[135, 135, 135, 135])
    t6_table.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
    ]))
    story.append(t6_table)

    # ==================== PAGE 2 ====================
    story.append(PageBreak())

    # Page 2 Subheader
    p2_head = [
        [
            Paragraph("<b>СТРАНИЦА 2 • ЗАКРЕПЛЕНИЕ, ЛОГИКА И ЗАДАЧИ</b>", ParagraphStyle('P2H', fontName='Nunito-Bold', fontSize=9.5, textColor=colors.HexColor('#0369A1'))),
            Paragraph("Внимательно читай условия и помни правило дополнения до 10!", ParagraphStyle('P2R', fontName='Nunito', fontSize=7.5, textColor=colors.HexColor('#64748B'), alignment=2))
        ]
    ]
    t_p2_head = Table(p2_head, colWidths=[300, 240])
    t_p2_head.setStyle(TableStyle([
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('TOPPADDING', (0,0), (-1,-1), 0),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 0),
    ]))
    story.append(t_p2_head)
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#38BDF8'), spaceAfter=4))

    # Task 7: Stepping stones chain
    story.append(Paragraph("<b>Задание 7. Цепочка примеров: «Прыгай по кочкам вместе с Зайчиком»</b>", task_num))
    story.append(create_stepping_stones_drawing())
    story.append(Spacer(1, 4))

    # Task 8: Missing numbers & Task 9: Neznayka Traps
    t8_content = """<b>Задание 8. «Числовые прятки»</b><br/>Вставь пропущенное число:<br/>
    • <b>[ &nbsp;&nbsp;&nbsp; ]</b> + 4 = 12 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • 13 − <b>[ &nbsp;&nbsp;&nbsp; ]</b> = 9<br/>
    • 8 + <b>[ &nbsp;&nbsp;&nbsp; ]</b> = 15 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • <b>[ &nbsp;&nbsp;&nbsp; ]</b> − 6 = 8<br/>
    • 9 + <b>[ &nbsp;&nbsp;&nbsp; ]</b> = 16 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; • 15 − <b>[ &nbsp;&nbsp;&nbsp; ]</b> = 7
    """
    t9_content = """<b>Задание 9. «Ловушка Незнайки»</b><br/>Незнайка спешил и ошибся! Зачеркни неверный ответ и напиши рядом правильный:<br/>
    1) 9 + 4 = 12 &nbsp;➔ <b>[ &nbsp;&nbsp;&nbsp; ]</b> &nbsp;&nbsp; 2) 8 + 5 = 13 &nbsp;➔ <b>[ &nbsp;&nbsp;&nbsp; ]</b><br/>
    3) 12 − 4 = 7 &nbsp;➔ <b>[ &nbsp;&nbsp;&nbsp; ]</b> &nbsp;&nbsp; 4) 14 − 6 = 8 &nbsp;➔ <b>[ &nbsp;&nbsp;&nbsp; ]</b><br/>
    5) 8 + 4 = 11 &nbsp;➔ <b>[ &nbsp;&nbsp;&nbsp; ]</b>
    """
    t8_9_table = Table([[Paragraph(t8_content, task_body), Paragraph(t9_content, task_body)]], colWidths=[270, 270])
    t8_9_table.setStyle(TableStyle([
        ('BOX', (0,0), (0,0), 0.8, colors.HexColor('#BAE6FD')),
        ('BOX', (1,0), (1,0), 0.8, colors.HexColor('#FECDD3')),
        ('BACKGROUND', (0,0), (0,0), colors.HexColor('#F8FAFC')),
        ('BACKGROUND', (1,0), (1,0), colors.HexColor('#FFF1F2')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t8_9_table)
    story.append(Spacer(1, 4))

    # Task 10: Comparisons
    story.append(Paragraph("<b>Задание 10. Сравни выражения (поставь знаки &gt;, &lt; или =):</b>", task_num))
    t10_data = [
        [
            Paragraph("9 + 4 &nbsp;<b>◯</b>&nbsp; 12", task_math),
            Paragraph("15 − 6 &nbsp;<b>◯</b>&nbsp; 10", task_math),
            Paragraph("8 + 5 &nbsp;<b>◯</b>&nbsp; 7 + 6", task_math),
            Paragraph("13 − 4 &nbsp;<b>◯</b>&nbsp; 12 − 3", task_math),
        ]
    ]
    t10_table = Table(t10_data, colWidths=[135, 135, 135, 135])
    t10_table.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
    ]))
    story.append(t10_table)
    story.append(Spacer(1, 4))

    # Tasks 11, 12, 13: Problems
    prob_11 = """<b>Задание 11. Простая задача</b><br/>
    У Зайчика было 9 морковок. Ёжик принёс ему ещё 4 морковки. Сколько всего морковок стало у Зайчика?<br/>
    <i>Краткая запись:</i> Было — 9 м.; Принёс — 4 м.; Стало — ? м.<br/>
    <i>Решение:</i> ________________________________________<br/>
    <i>Ответ:</i> Всего стало _____ морковок.
    """
    prob_12 = """<b>Задание 12. Задача в два действия</b><br/>
    На полянке играли 8 зайчат, а бельчат — на 4 больше. Сколько всего зверят играло на полянке?<br/>
    <i>1) Сколько бельчат?</i> ______________________________<br/>
    <i>2) Сколько всего зверят?</i> __________________________<br/>
    <i>Ответ:</i> Всего _____ зверят.
    """
    prob_table = Table([[Paragraph(prob_11, task_body), Paragraph(prob_12, task_body)]], colWidths=[270, 270])
    prob_table.setStyle(TableStyle([
        ('BOX', (0,0), (0,0), 0.8, colors.HexColor('#E2E8F0')),
        ('BOX', (1,0), (1,0), 0.8, colors.HexColor('#E2E8F0')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FFFFFF')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(prob_table)
    story.append(Spacer(1, 4))

    # Task 13: Star problem (indirect)
    prob_13 = """<b>⭐ Задание 13. Олимпиадная задача на сообразительность</b><br/>
    У белочки 13 орешков, это на 5 орешков больше, чем у Зайчика. Сколько орешков у Зайчика?<br/>
    <i>Решение:</i> __________________________________________________ &nbsp;&nbsp;&nbsp;&nbsp; <i>Ответ:</i> У Зайчика _____ орешков.
    """
    t13_table = Table([[Paragraph(prob_13, task_body)]], colWidths=[540])
    t13_table.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.8, colors.HexColor('#FDE047')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FEFCE8')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t13_table)
    story.append(Spacer(1, 4))

    # Self-check carrots
    story.append(create_carrots_self_check())
    story.append(Spacer(1, 4))

    # Teacher's Key Box
    key_text = """<b>🔑 Ключи и ответы для учителя:</b><br/>
    <b>З.1:</b> 14, 17, 1 дес. 6 ед., 1 дес. 9 ед. | <b>З.2:</b> 1, 2, 3, 4, 5, 1. | <b>З.4:</b> 8+5=8+(2+3)=10+3=13; 9+5=9+(1+4)=10+4=14; 7+5=7+(3+2)=10+2=12; 8+4=8+(2+2)=10+2=12; 9+6=9+(1+5)=10+5=15. | <b>З.5:</b> 14−6=(14−4)−2=8; 13−5=(13−3)−2=8; 11−4=(11−1)−3=7; 15−7=(15−5)−2=8; 12−5=(12−2)−3=7. | <b>З.6:</b> 12, 8, 14, 9, 11, 7, 16, 9. | <b>З.7:</b> 9 ➔ 12 ➔ 7 ➔ 15 ➔ 5. | <b>З.8:</b> 8, 4, 7, 14, 7, 8. | <b>З.9:</b> Ошибки в №1 (13), №3 (8), №5 (12). | <b>З.10:</b> &gt;, &lt;, =, =. | <b>З.11:</b> 9+4=13 (м.). | <b>З.12:</b> 1) 8+4=12 (б.); 2) 8+12=20 (зв.). | <b>З.13:</b> 13−5=8 (ор.).
    """
    t_key = Table([[Paragraph(key_text, key_style)]], colWidths=[540])
    t_key.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_key)

    doc.build(story, canvasmaker=WorksheetCanvas)
    print(f"Built {output_path} successfully!")

if __name__ == '__main__':
    out_dir = 'materials_1grade_ten_transition'
    os.makedirs(out_dir, exist_ok=True)
    build_worksheet_pdf(os.path.join(out_dir, '2_Rabochiy_list_perehod_cherez_desyatok.pdf'))

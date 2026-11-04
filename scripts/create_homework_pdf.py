import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.graphics.shapes import Drawing, Rect, Circle, Line, String, Group, Polygon

pdfmetrics.registerFont(TTFont('Nunito', 'Nunito-Regular.ttf'))
pdfmetrics.registerFont(TTFont('Nunito-Bold', 'Nunito-Bold.ttf'))

class HomeworkCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(HomeworkCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(HomeworkCanvas, self).showPage()
        super(HomeworkCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        page_w, page_h = A4
        # Top color accent bar (Emerald green)
        self.setFillColor(colors.HexColor('#059669'))
        self.rect(26, page_h - 16, page_w - 52, 3, fill=True, stroke=False)
        
        # Bottom footer bar
        self.setFillColor(colors.HexColor('#E2E8F0'))
        self.rect(26, 18, page_w - 52, 1, fill=True, stroke=False)
        self.setFont('Nunito-Bold', 7)
        self.setFillColor(colors.HexColor('#059669'))
        self.drawString(26, 10, "ДОМАШНЕЕ ЗАДАНИЕ ПО МАТЕМАТИКЕ • 1 КЛАСС")
        self.setFont('Nunito', 7)
        self.setFillColor(colors.HexColor('#64748B'))
        self.drawRightString(page_w - 26, 10, "Традиционная арифметика (А. С. Пчёлко, Г. В. Поляк)")
        self.restoreState()

def create_hw_sticks_drawing():
    """Drawing of problem with sticks for homework"""
    d = Drawing(250, 36)
    d.add(Rect(0, 0, 250, 36, rx=4, ry=4, fillColor=colors.HexColor('#F0FDF4'), strokeColor=colors.HexColor('#BBF7D0'), strokeWidth=0.8))
    
    # Left: 1 bundle of 10
    d.add(Rect(10, 4, 38, 22, rx=2, ry=2, fillColor=colors.HexColor('#FEF3C7'), strokeColor=colors.HexColor('#F59E0B'), strokeWidth=0.8))
    for i in range(8):
        x = 13 + i * 4.2
        d.add(Line(x, 5, x, 25, strokeColor=colors.HexColor('#B45309'), strokeWidth=1.2))
    d.add(Rect(10, 12, 38, 5, fillColor=colors.HexColor('#2563EB'), strokeColor=None))
    d.add(String(12, 28, "1 десяток (10)", fontName='Nunito-Bold', fontSize=6.5, fillColor=colors.HexColor('#B45309')))
    
    # Loose sticks (4)
    for i in range(4):
        x = 56 + i * 7
        d.add(Line(x, 5, x, 22, strokeColor=colors.HexColor('#D97706'), strokeWidth=1.5))
    d.add(String(56, 26, "4 ед.", fontName='Nunito-Bold', fontSize=6.5, fillColor=colors.HexColor('#059669')))
    
    # Cross out 6 sticks (4 loose and 2 from bundle)
    d.add(String(92, 12, "Зачеркни 6 ➔", fontName='Nunito-Bold', fontSize=7.5, fillColor=colors.HexColor('#DC2626')))
    d.add(String(155, 12, "14 − 6 = [ ___ ]", fontName='Nunito-Bold', fontSize=9, fillColor=colors.HexColor('#0F172A')))
    return d

def build_homework_pdf(output_path):
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        leftMargin=26,
        rightMargin=26,
        topMargin=20,
        bottomMargin=20
    )

    styles = getSampleStyleSheet()

    sec_title = ParagraphStyle(
        'SecTitle',
        fontName='Nunito-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor('#065F46'),
        spaceBefore=3,
        spaceAfter=2
    )
    body_hw = ParagraphStyle(
        'BodyHw',
        fontName='Nunito',
        fontSize=7.5,
        leading=10.5,
        textColor=colors.HexColor('#1E293B'),
        spaceAfter=2
    )
    math_hw = ParagraphStyle(
        'MathHw',
        fontName='Nunito-Bold',
        fontSize=8,
        leading=11,
        textColor=colors.HexColor('#0F172A'),
        alignment=1
    )
    memo_title = ParagraphStyle(
        'MemoTitle',
        fontName='Nunito-Bold',
        fontSize=8,
        leading=10.5,
        textColor=colors.HexColor('#B45309')
    )
    memo_body = ParagraphStyle(
        'MemoBody',
        fontName='Nunito',
        fontSize=7,
        leading=9.5,
        textColor=colors.HexColor('#78350F')
    )

    story = []

    # Title & Student Fields Table
    header_table_data = [
        [
            Paragraph("<b>ДОМАШНЕЕ ЗАДАНИЕ ПО МАТЕМАТИКЕ • 1 КЛАСС</b><br/>Тема: «Сложение и вычитание с переходом через десяток»", ParagraphStyle('HH', fontName='Nunito-Bold', fontSize=10, leading=12.5, textColor=colors.HexColor('#065F46'))),
            Paragraph("<b>Фамилия, имя:</b> ___________________________<br/><b>Дата сдачи:</b> ___________________", ParagraphStyle('HF', fontName='Nunito', fontSize=8, leading=11, textColor=colors.HexColor('#1E293B')))
        ]
    ]
    t_head = Table(header_table_data, colWidths=[320, 220])
    t_head.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#ECFDF5')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#A7F3D0')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_head)
    story.append(Spacer(1, 3))

    # 1. Повторение
    story.append(Paragraph("<b>1. Разминка и повторение фундамента</b>", sec_title))
    rev_data = [
        [
            Paragraph("<b>Дополни до 10:</b><br/>9 + <b>[ &nbsp; ]</b> = 10 &nbsp;&nbsp;&nbsp;&nbsp; 8 + <b>[ &nbsp; ]</b> = 10<br/>7 + <b>[ &nbsp; ]</b> = 10 &nbsp;&nbsp;&nbsp;&nbsp; 6 + <b>[ &nbsp; ]</b> = 10", body_hw),
            Paragraph("<b>Разрядный состав чисел:</b><br/>1 дес. 5 ед. = <b>[ &nbsp;&nbsp; ]</b> &nbsp;&nbsp;&nbsp;&nbsp; 1 дес. 8 ед. = <b>[ &nbsp;&nbsp; ]</b><br/>13 = <b>[ &nbsp;&nbsp; ]</b> дес. <b>[ &nbsp;&nbsp; ]</b> ед.", body_hw),
        ]
    ]
    t_rev = Table(rev_data, colWidths=[270, 270])
    t_rev.setStyle(TableStyle([
        ('BOX', (0,0), (0,0), 0.6, colors.HexColor('#CBD5E1')),
        ('BOX', (1,0), (1,0), 0.6, colors.HexColor('#CBD5E1')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_rev)
    story.append(Spacer(1, 3))

    # 2. Основная часть (8-10 примеров)
    story.append(Paragraph("<b>2. Основная тренировка (решай по частям с опорой на десяток):</b>", sec_title))
    ex_data = [
        [
            Paragraph("9 + 4 = 9 + (1 + 3) = <b>13</b>", ParagraphStyle('E0', fontName='Nunito', fontSize=7.5, textColor=colors.HexColor('#64748B'))),
            Paragraph("8 + 5 = 8 + (<b>[ &nbsp; ]</b> + <b>[ &nbsp; ]</b>) = <b>[ &nbsp;&nbsp; ]</b>", math_hw),
            Paragraph("12 − 4 = (12 − 2) − 2 = <b>8</b>", ParagraphStyle('E0', fontName='Nunito', fontSize=7.5, textColor=colors.HexColor('#64748B'))),
            Paragraph("14 − 6 = (14 − <b>[ &nbsp; ]</b>) − <b>[ &nbsp; ]</b> = <b>[ &nbsp;&nbsp; ]</b>", math_hw),
        ],
        [
            Paragraph("9 + 5 = <b>[ &nbsp;&nbsp; ]</b>", math_hw),
            Paragraph("8 + 4 = <b>[ &nbsp;&nbsp; ]</b>", math_hw),
            Paragraph("13 − 5 = <b>[ &nbsp;&nbsp; ]</b>", math_hw),
            Paragraph("11 − 3 = <b>[ &nbsp;&nbsp; ]</b>", math_hw),
        ],
        [
            Paragraph("7 + 5 = <b>[ &nbsp;&nbsp; ]</b>", math_hw),
            Paragraph("9 + 7 = <b>[ &nbsp;&nbsp; ]</b>", math_hw),
            Paragraph("15 − 7 = <b>[ &nbsp;&nbsp; ]</b>", math_hw),
            Paragraph("12 − 5 = <b>[ &nbsp;&nbsp; ]</b>", math_hw),
        ]
    ]
    t_ex = Table(ex_data, colWidths=[135, 135, 135, 135])
    t_ex.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('BACKGROUND', (0,0), (0,0), colors.HexColor('#F1F5F9')),
        ('BACKGROUND', (2,0), (2,0), colors.HexColor('#F1F5F9')),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
    ]))
    story.append(t_ex)
    story.append(Spacer(1, 3))

    # 3. Цепочка и Сравнение
    chain_comp_data = [
        [
            Paragraph("<b>Цепочка вычислений:</b><br/>8 &nbsp;<b>+ 4</b> ➔ <b>[ &nbsp;&nbsp; ]</b> &nbsp;<b>− 3</b> ➔ <b>[ &nbsp;&nbsp; ]</b> &nbsp;<b>+ 6</b> ➔ <b>[ &nbsp;&nbsp; ]</b> &nbsp;<b>− 10</b> ➔ <b>[ &nbsp;&nbsp; ]</b>", body_hw),
            Paragraph("<b>Сравни выражени (&gt;, &lt;, =):</b><br/>9 + 3 &nbsp;<b>◯</b>&nbsp; 11 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 14 − 5 &nbsp;<b>◯</b>&nbsp; 8<br/>8 + 6 &nbsp;<b>◯</b>&nbsp; 9 + 5 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 13 − 4 &nbsp;<b>◯</b>&nbsp; 10", body_hw)
        ]
    ]
    t_chain = Table(chain_comp_data, colWidths=[270, 270])
    t_chain.setStyle(TableStyle([
        ('BOX', (0,0), (0,0), 0.6, colors.HexColor('#E2E8F0')),
        ('BOX', (1,0), (1,0), 0.6, colors.HexColor('#E2E8F0')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FFFFFF')),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_chain)
    story.append(Spacer(1, 3))

    # 4. Задача по рисунку палочек
    story.append(Paragraph("<b>3. Задача по рисунку (рассмотри палочки Зайчика и реши):</b>", sec_title))
    prob_hw_data = [
        [
            create_hw_sticks_drawing(),
            Paragraph("<b>Условие:</b> У Зайчика было 14 палочек (1 пучок-десяток и 4 палочки). Он отдал Белочке 6 палочек.<br/>Сколько палочек осталось у Зайчика?<br/><i>Решение:</i> 14 − 4 − 2 = <b>[ &nbsp;&nbsp; ]</b> (п.)<br/><i>Ответ:</i> Осталось _____ палочек.", body_hw)
        ]
    ]
    t_prob = Table(prob_hw_data, colWidths=[255, 285])
    t_prob.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.6, colors.HexColor('#A7F3D0')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('LEFTPADDING', (0,0), (-1,-1), 4),
        ('RIGHTPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_prob)
    story.append(Spacer(1, 3))

    # 5. Творческое мини-задание
    creat_text = """<b>4. Творческое задание Зайчика (на выбор):</b><br/>
    Придумай и нарисуй в рамочке свой пример на сложение или вычитание с переходом через десяток (нарисуй пучок из 10 палочек и свободные палочки). Подпиши решение!<br/>
    <i>Рамочка для твоего рисунка:</i> [ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ]
    """
    t_creat = Table([[Paragraph(creat_text, body_hw)]], colWidths=[540])
    t_creat.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.6, colors.HexColor('#FDE047')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FEFCE8')),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_creat)
    story.append(Spacer(1, 3))

    # 6. Памятка для родителей (шпаргалка составов чисел 2-10 и алгоритм)
    memo_header = Paragraph("<b>📌 ПАМЯТКА ДЛЯ РОДИТЕЛЕЙ (Методический совет учителя начальных классов):</b>", memo_title)
    memo_content = """
    <b>1. Не разрешайте считать на пальцах!</b> Пальчиковый пересчёт по единичке тормозит развитие мышления и вызовет тяжёлые трудности во 2 классе. Требуйте от ребёнка обязательного объяснения вслух:<br/>
    • <i>При сложении:</i> «Дополняю до 10. К 9 прибавлю 1, будет 10. Число 4 — это 1 и 3. К 10 прибавлю 3, получится 13».<br/>
    • <i>При вычитании:</i> «Уменьшаю до 10. Из 12 вычту сначала 2, будет 10. Число 4 — это 2 и 2. Из 10 вычту 2, останется 8».<br/>
    <b>2. Шпаргалка составов чисел для повторения дома:</b><br/>
    <b>10</b> = 9+1 | 8+2 | 7+3 | 6+4 | 5+5 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <b>5</b> = 1+4 | 2+3 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <b>4</b> = 1+3 | 2+2 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <b>3</b> = 1+2 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <b>2</b> = 1+1
    """
    t_memo = Table([[memo_header], [Paragraph(memo_content, memo_body)]], colWidths=[540])
    t_memo.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.8, colors.HexColor('#D97706')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FFFBEB')),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_memo)

    doc.build(story, canvasmaker=HomeworkCanvas)
    print(f"Built {output_path} successfully!")

if __name__ == '__main__':
    out_dir = 'materials_1grade_ten_transition'
    os.makedirs(out_dir, exist_ok=True)
    build_homework_pdf(os.path.join(out_dir, '3_Domashnee_zadanie_perehod_cherez_desyatok.pdf'))

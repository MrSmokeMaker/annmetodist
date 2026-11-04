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

class RussianHomeworkCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(RussianHomeworkCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(RussianHomeworkCanvas, self).showPage()
        super(RussianHomeworkCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        page_w, page_h = A4
        # Top color accent bar (Deep forest green)
        self.setFillColor(colors.HexColor('#166534'))
        self.rect(26, page_h - 16, page_w - 52, 3, fill=True, stroke=False)
        
        # Bottom footer bar
        self.setFillColor(colors.HexColor('#E7E5E4'))
        self.rect(26, 18, page_w - 52, 1, fill=True, stroke=False)
        self.setFont('Nunito-Bold', 7)
        self.setFillColor(colors.HexColor('#166534'))
        self.drawString(26, 10, "ДОМАШНЕЕ ЗАДАНИЕ ПО РУССКОМУ ЯЗЫКУ • 2 КЛАСС")
        self.setFont('Nunito', 7)
        self.setFillColor(colors.HexColor('#78716C'))
        self.drawRightString(page_w - 26, 10, "Классическая советская методика Н. А. Костина (1949)")
        self.restoreState()

def create_word_house_drawing():
    """Drawing of 'Домик слова' according to Kostin metaphor: Foundation = Root, Door/Roof = Ending"""
    d = Drawing(540, 32)
    d.add(Rect(0, 0, 540, 32, rx=4, ry=4, fillColor=colors.HexColor('#FEFCE8'), strokeColor=colors.HexColor('#FEF08A'), strokeWidth=0.8))
    
    # Left: House diagram
    # Base/foundation: Корень
    d.add(Rect(14, 4, 76, 14, rx=2, ry=2, fillColor=colors.HexColor('#DC2626'), strokeColor=colors.HexColor('#B91C1C'), strokeWidth=0.8))
    d.add(String(20, 8, "КОРЕНЬ [лес-]", fontName='Nunito-Bold', fontSize=6.5, fillColor=colors.white))
    
    # Removable door: Окончание
    d.add(Rect(94, 4, 52, 14, rx=2, ry=2, fillColor=colors.HexColor('#2563EB'), strokeColor=colors.HexColor('#1D4ED8'), strokeWidth=0.8))
    d.add(String(98, 8, "ОКОНЧ. [-а/-у]", fontName='Nunito-Bold', fontSize=6.5, fillColor=colors.white))
    
    # Roof: Основа
    d.add(Polygon([14, 20, 146, 20, 80, 28], fillColor=colors.HexColor('#D97706'), strokeColor=colors.HexColor('#B45309'), strokeWidth=0.8))
    d.add(String(56, 22, "ОСНОВА СЛОВА", fontName='Nunito-Bold', fontSize=5.5, fillColor=colors.white))
    
    # Explanatory text
    d.add(String(160, 18, "💡 Образное правило Костина: «Корень и основа — это прочный фундамент дома,", fontName='Nunito-Bold', fontSize=7, fillColor=colors.HexColor('#854D0E')))
    d.add(String(160, 7, "а окончание — сменная дверка: меняется в зависимости от того, кто пришёл в гости в предложении!»", fontName='Nunito', fontSize=7, fillColor=colors.HexColor('#713F12')))
    return d

def build_russian_homework_pdf(output_path):
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
        textColor=colors.HexColor('#14532D'),
        spaceBefore=3,
        spaceAfter=1.5
    )
    body_hw = ParagraphStyle(
        'BodyHw',
        fontName='Nunito',
        fontSize=7.5,
        leading=10.5,
        textColor=colors.HexColor('#1C1917'),
        spaceAfter=1.5
    )
    memo_title = ParagraphStyle(
        'MemoTitle',
        fontName='Nunito-Bold',
        fontSize=7.8,
        leading=10,
        textColor=colors.HexColor('#854D0E')
    )
    memo_body = ParagraphStyle(
        'MemoBody',
        fontName='Nunito',
        fontSize=6.8,
        leading=9.2,
        textColor=colors.HexColor('#713F12')
    )

    story = []

    # Title & Student Fields Table
    header_table_data = [
        [
            Paragraph("<b>ДОМАШНЕЕ ЗАДАНИЕ ПО РУССКОМУ ЯЗЫКУ • 2 КЛАСС</b><br/>Тема: «Что такое окончание слова» (методика Н. А. Костина)", ParagraphStyle('HH', fontName='Nunito-Bold', fontSize=10, leading=12.5, textColor=colors.HexColor('#14532D'))),
            Paragraph("<b>Фамилия, имя:</b> ___________________________<br/><b>Дата выполнения:</b> ___________________", ParagraphStyle('HF', fontName='Nunito', fontSize=8, leading=11, textColor=colors.HexColor('#1C1917')))
        ]
    ]
    t_head = Table(header_table_data, colWidths=[320, 220])
    t_head.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F0FDF4')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#BBF7D0')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_head)
    story.append(Spacer(1, 2.5))

    # 1. Повторение (корень и формы слова)
    story.append(Paragraph("<b>1. Повторение: гнездо родственных слов и формы слова</b>", sec_title))
    rev_data = [
        [
            Paragraph("<b>а) Выделите корень дугой в родственных словах:</b><br/><i>Зима, зимний, зимовать, зимовье, перезимовать.</i><br/>Корень во всех словах: <b>[ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ]</b>", body_hw),
            Paragraph("<b>б) Докажите, что это формы одного слова:</b><br/><i>Зима, зимы, к зиме, зиму, зимой, о зиме.</i><br/>Значение слова не меняется, меняется только: <b>[ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ]</b>", body_hw),
        ]
    ]
    t_rev = Table(rev_data, colWidths=[270, 270])
    t_rev.setStyle(TableStyle([
        ('BOX', (0,0), (0,0), 0.6, colors.HexColor('#CBD5E1')),
        ('BOX', (1,0), (1,0), 0.6, colors.HexColor('#CBD5E1')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FAFAF9')),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_rev)
    story.append(Spacer(1, 2.5))

    # 2. Основная тренировка (изменение слов по вопросам + вставка в предложения)
    story.append(Paragraph("<b>2. Основная часть: изменение слов и выделение окончаний</b>", sec_title))
    ex_data = [
        [
            Paragraph("""<b>Измените слова по вопросам и подчеркните окончания:</b><br/>
            • <b>трава</b> ➔ нет трав[ &nbsp;&nbsp; ], к трав[ &nbsp;&nbsp; ], трав[ &nbsp;&nbsp; ]<br/>
            • <b>сосна</b> ➔ нет сосн[ &nbsp;&nbsp; ], любуюсь сосн[ &nbsp;&nbsp; ]<br/>
            • <b>мороз</b> ➔ нет мороз[ &nbsp;&nbsp; ], мороз[ &nbsp;&nbsp; ] (нулевое: мороз□)""", body_hw),
            Paragraph("""<b>Вставьте пропущенные окончания для связи слов:</b><br/>
            1) Пушист<b>[ &nbsp;&nbsp; ]</b> снег укрыл лесн<b>[ &nbsp;&nbsp; ]</b> поляну.<br/>
            2) На верхушк<b>[ &nbsp;&nbsp; ]</b> старой ел<b>[ &nbsp;&nbsp; ]</b> сидит сорока.<br/>
            3) Маленьк<b>[ &nbsp;&nbsp; ]</b> зайчик спрятался под кустом.""", body_hw)
        ]
    ]
    t_ex = Table(ex_data, colWidths=[270, 270])
    t_ex.setStyle(TableStyle([
        ('BOX', (0,0), (0,0), 0.6, colors.HexColor('#CBD5E1')),
        ('BOX', (1,0), (1,0), 0.6, colors.HexColor('#CBD5E1')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FFFFFF')),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_ex)
    story.append(Spacer(1, 2.5))

    # 3. Списывание предложения
    story.append(Paragraph("<b>3. Списывание с грамматическим заданием по Костину:</b>", sec_title))
    copy_text = """Спишите предложение. Подчеркните окончания во всех словах одной чертой:<br/>
    <i>Рыжая лисица выследила в овраге серого зайчишку.</i><br/>
    ____________________________________________________________________________________________________
    """
    t_copy = Table([[Paragraph(copy_text, body_hw)]], colWidths=[540])
    t_copy.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.6, colors.HexColor('#D1D5DB')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_copy)
    story.append(Spacer(1, 2.5))

    # 4. Образная схема «Домик слова»
    story.append(create_word_house_drawing())
    story.append(Spacer(1, 2.5))

    # 5. Творческое задание
    creat_text = """<b>4. Творческое задание Хитрой Лисы (на выбор):</b><br/>
    <b>Вариант А:</b> Выбери своё любимое слово (например: <i>кошка, дружба, река</i>), измени его по 3 вопросам и подчеркни окончания: _______________________________________________________________________________________<br/>
    <b>Вариант Б:</b> Нарисуй свой «Домик слова» в тетради и покажи, как меняется окончание-дверка!
    """
    t_creat = Table([[Paragraph(creat_text, body_hw)]], colWidths=[540])
    t_creat.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.6, colors.HexColor('#FED7AA')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FFFBEB')),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_creat)
    story.append(Spacer(1, 2.5))

    # 6. Памятка для родителей в духе советской традиции
    memo_header = Paragraph("<b>📌 ПАМЯТКА ДЛЯ РОДИТЕЛЕЙ (Советская традиция преподавания русского языка):</b>", memo_title)
    memo_content = """
    <b>1. Как правильно проверять ребёнка:</b> Никогда не подсказывайте готовый ответ и не разрешайте угадывать окончание «на глаз»!<br/>
    • Требуйте от ребёнка обязательного применения <b>приёма изменения формы слова</b>: <i>«Измени слово: книга — нет книг-и, любуюсь книг-ой. Какая буква на конце меняется? Буква -а меняется на -и, -ой! Значит, окончание — только -а!»</i>.<br/>
    <b>2. Главная ловушка: окончание — это НЕ последний слог!</b><br/>
    В словах <i>пар-та, кни-га, берё-за</i> дети часто ошибочно выделяют <i>-та, -га, -за</i>. Объясните: согласные звуки [т], [г], [з] входят в корень и никогда не меняются. Окончание — только гласная буква на конце!<br/>
    <b>3. Твёрдо выучите наизусть формулировку правила из учебника Н. А. Костина:</b><br/>
    <i>«Окончанием называется изменяемая часть слова, которая служит для связи слов в предложении».</i>
    """
    t_memo = Table([[memo_header], [Paragraph(memo_content, memo_body)]], colWidths=[540])
    t_memo.setStyle(TableStyle([
        ('BOX', (0,0), (-1,-1), 0.8, colors.HexColor('#CA8A04')),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#FEFCE8')),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_memo)

    doc.build(story, canvasmaker=RussianHomeworkCanvas)
    print(f"Built {output_path} successfully!")

if __name__ == '__main__':
    out_dir = 'materials_2grade_russian_ending'
    os.makedirs(out_dir, exist_ok=True)
    build_russian_homework_pdf(os.path.join(out_dir, '3_List_domashnego_zadaniya_Kostin_Okonchanie_2klass.pdf'))

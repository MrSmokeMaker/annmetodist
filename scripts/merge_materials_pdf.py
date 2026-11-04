import os
from pypdf import PdfWriter

def merge_pdfs(file_list, output_path):
    writer = PdfWriter()
    for f in file_list:
        print(f"Adding: {f}")
        writer.append(f)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "wb") as f_out:
        writer.write(f_out)
    writer.close()
    print(f"Successfully created: {output_path}")

def main():
    # 1. Math: Переход через десяток (1 класс, Пчёлко)
    math_files = [
        "materials_1grade_ten_transition/1_Konspekt_uroka_Pchelko_1klass.pdf",
        "materials_1grade_ten_transition/2_Rabochiy_list_perehod_cherez_desyatok.pdf",
        "materials_1grade_ten_transition/3_Domashnee_zadanie_perehod_cherez_desyatok.pdf",
    ]
    math_output = "materials_1grade_ten_transition/Komplekt_1klass_perehod_cherez_desyatok_Pchelko.pdf"
    merge_pdfs(math_files, math_output)

    # 2. Russian: Окончание (2 класс, Костин)
    rus_files = [
        "materials_2grade_russian_ending/1_Konspekt_zanyatiya_Kostin_Okonchanie_2klass.pdf",
        "materials_2grade_russian_ending/2_List_zadaniy_Kostin_Okonchanie_2klass.pdf",
        "materials_2grade_russian_ending/3_List_domashnego_zadaniya_Kostin_Okonchanie_2klass.pdf",
    ]
    rus_output = "materials_2grade_russian_ending/Komplekt_2klass_okonchanie_Kostin.pdf"
    merge_pdfs(rus_files, rus_output)

if __name__ == "__main__":
    main()

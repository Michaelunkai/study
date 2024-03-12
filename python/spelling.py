import enchant

def fix_spelling(text):
    d = enchant.Dict("en_US")  # Load English dictionary
    words = text.split()
    fixed_text = []
    for word in words:
        if not d.check(word):  # Check if the word is misspelled
            suggestions = d.suggest(word)
            if suggestions:
                fixed_text.append(suggestions[0])  # Choose the first suggestion
            else:
                fixed_text.append(word)  # If no suggestions, keep the original word
        else:
            fixed_text.append(word)  # If spelled correctly, keep the original word
    return ' '.join(fixed_text)

def main():
    file_path = input("Enter the path of the file: ")
    try:
        with open(file_path, 'r') as file:
            text = file.read()
            fixed_text = fix_spelling(text)
            print("Fixed text:\n", fixed_text)
    except FileNotFoundError:
        print("File not found.")

if __name__ == "__main__":
    main()

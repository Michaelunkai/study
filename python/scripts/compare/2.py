import tkinter as tk

def highlight_differences(text1, text2):
    highlighted_indices = []

    # Compare each character in text2 with the corresponding character in text1
    for i, char2 in enumerate(text2):
        if i < len(text1) and char2 != text1[i]:
            highlighted_indices.append(i)

    return highlighted_indices

def compare_text(event=None):
    text1 = text_box1.get("1.0", "end-1c")
    text2 = text_box2.get("1.0", "end-1c")

    highlighted_indices = highlight_differences(text1, text2)

    text_box2.tag_remove("highlight", "1.0", "end")

    for index in highlighted_indices:
        start_pos = f"1.{index}"
        end_pos = f"1.{index + 1}"
        text_box2.tag_add("highlight", start_pos, end_pos)
        text_box2.tag_config("highlight", foreground="red")

# Create the main window
root = tk.Tk()
root.title("Text Comparison App")
root.configure(bg="#6B7B8C")  # Light navy blue background color

# Create text entry boxes
text_box_frame1 = tk.Frame(root, bg="#6B7B8C")
text_box_frame1.pack(side="left", padx=5, pady=5)
text_box1 = tk.Text(text_box_frame1, height=20, width=55, bg="white", wrap=tk.WORD)  # Word wrapping
text_box1.pack(side="top")

text_box_frame2 = tk.Frame(root, bg="#6B7B8C")
text_box_frame2.pack(side="left", padx=5, pady=5)
text_box2 = tk.Text(text_box_frame2, height=20, width=55, bg="white", wrap=tk.WORD)  # Word wrapping
text_box2.pack(side="top")

# Bind the compare_text function to the text boxes
text_box1.bind("<KeyRelease>", compare_text)
text_box2.bind("<KeyRelease>", compare_text)

root.mainloop()

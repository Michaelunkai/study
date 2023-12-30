# # quiz game
# #------------------------------
# def new_game():
#     pass
# #------------------------------
# def check_answer():
#     pass
# #------------------------------
# def display_score():
#     pass
# #------------------------------
# def play_again():
#     pass
# #------------------------------

# questions = {
#     "who create Python?: ": "A",
#     "What year was Python created?: ": "B",
#     "Python is tributed to which comedy group?: ": "C",
#     "Is the Earth round?: ": "A"
# }

# options = [["A. Guido van Rossum", "B. Elon Musk", "C. Bill Gates", "D. mark Zockerburg"],
#           ["A. 1989", "B. 1991", "C. 2000", "D. 2016"],
#           ["A. lonley Island", "B. Smosh", "C. Monty Python", "D. SNL"],
#           ["A. True", "B. False", "C. sometimes", "D. what's Earth?"]]

# new_game()

# quiz game
# #------------------------------
# def new_game():
    
#     guesses = []
#     correct_guesses = 0
#     question_num = 1

#     for key in questions:
#         print(key)
# #------------------------------
# def check_answer():
#     pass
# #------------------------------
# def display_score():
#     pass
# #------------------------------
# def play_again():
#     pass
# #------------------------------

# questions = {
#     "who create Python?: ": "A",
#     "What year was Python created?: ": "B",
#     "Python is tributed to which comedy group?: ": "C",
#     "Is the Earth round?: ": "A"
# }

# options = [["A. Guido van Rossum", "B. Elon Musk", "C. Bill Gates", "D. mark Zockerburg"],
#           ["A. 1989", "B. 1991", "C. 2000", "D. 2016"],
#           ["A. lonley Island", "B. Smosh", "C. Monty Python", "D. SNL"],
#           ["A. True", "B. False", "C. sometimes", "D. what's Earth?"]]

# new_game()

# output: who create Python?: 
# What year was Python created?: 
# Python is tributed to which comedy group?: 
# Is the Earth round?: 


# #------------------------------
# def new_game():
    
#     guesses = []
#     correct_guesses = 0
#     question_num = 1

#     for key in questions:
#         print("-------------------------")
#         print(key)
#         for i in options:
#             print(i)
# #------------------------------
# def check_answer():
#     pass
# #------------------------------
# def display_score():
#     pass
# #------------------------------
# def play_again():
#     pass
# #------------------------------

# questions = {
#     "who create Python?: ": "A",
#     "What year was Python created?: ": "B",
#     "Python is tributed to which comedy group?: ": "C",
#     "Is the Earth round?: ": "A"
# }

# options = [["A. Guido van Rossum", "B. Elon Musk", "C. Bill Gates", "D. mark Zockerburg"],
#           ["A. 1989", "B. 1991", "C. 2000", "D. 2016"],
#           ["A. lonley Island", "B. Smosh", "C. Monty Python", "D. SNL"],
#           ["A. True", "B. False", "C. sometimes", "D. what's Earth?"]]

# new_game()


# output:
# -------------------------
# who create Python?: 
# ['A. Guido van Rossum', 'B. Elon Musk', 'C. Bill Gates', 'D. mark Zockerburg']
# ['A. 1989', 'B. 1991', 'C. 2000', 'D. 2016']
# ['A. lonley Island', 'B. Smosh', 'C. Monty Python', 'D. SNL']
# ['A. True', 'B. False', 'C. sometimes', "D. what's Earth?"]
# -------------------------
# What year was Python created?: 
# ['A. Guido van Rossum', 'B. Elon Musk', 'C. Bill Gates', 'D. mark Zockerburg']
# ['A. 1989', 'B. 1991', 'C. 2000', 'D. 2016']
# ['A. lonley Island', 'B. Smosh', 'C. Monty Python', 'D. SNL']
# ['A. True', 'B. False', 'C. sometimes', "D. what's Earth?"]
# -------------------------
# Python is tributed to which comedy group?: 
# ['A. Guido van Rossum', 'B. Elon Musk', 'C. Bill Gates', 'D. mark Zockerburg']
# ['A. 1989', 'B. 1991', 'C. 2000', 'D. 2016']
# ['A. lonley Island', 'B. Smosh', 'C. Monty Python', 'D. SNL']
# ['A. True', 'B. False', 'C. sometimes', "D. what's Earth?"]
# -------------------------
# Is the Earth round?: 
# ['A. Guido van Rossum', 'B. Elon Musk', 'C. Bill Gates', 'D. mark Zockerburg']
# ['A. 1989', 'B. 1991', 'C. 2000', 'D. 2016']
# ['A. lonley Island', 'B. Smosh', 'C. Monty Python', 'D. SNL']
# ['A. True', 'B. False', 'C. sometimes', "D. what's Earth?"]

#------------------------------
def new_game():
    
    guesses = []
    correct_guesses = 0
    question_num = 1

    for key in questions:
        print("-------------------------")
        print(key)
        for i in options:
            print(i)
#------------------------------
def check_answer():
    pass
#------------------------------
def display_score():
    pass
#------------------------------
def play_again():
    pass
#------------------------------

questions = {
    "who create Python?: ": "A",
    "What year was Python created?: ": "B",
    "Python is tributed to which comedy group?: ": "C",
    "Is the Earth round?: ": "A"
}

options = [["A. Guido van Rossum", "B. Elon Musk", "C. Bill Gates", "D. mark Zockerburg"],
          ["A. 1989", "B. 1991", "C. 2000", "D. 2016"],
          ["A. lonley Island", "B. Smosh", "C. Monty Python", "D. SNL"],
          ["A. True", "B. False", "C. sometimes", "D. what's Earth?"]]

new_game()
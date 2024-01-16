# # if_name_ == '__main__'
# # if __name__ == '__main__' checks if the Python script is being run directly,
# # allowing or preventing specific
# # code from executing when the script
# # is imported.

# if __name__ == '__main__':
#     pass

# print(__name__)
# output: __main__

# ------------------------------------
def main():
    print("This is the main function.")

if __name__ == '__main__':
    main()
# output: This is the main function.
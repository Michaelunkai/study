from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def index():
    # Replace this list with your skills
    skills = ["Skill 1", "Skill 2", "Skill 3", "Skill 4"]
    return render_template('index.html', skills=skills)

if __name__ == '__main__':
    app.run(debug=True)

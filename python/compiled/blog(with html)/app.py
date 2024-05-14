from flask import Flask, render_template, redirect
from flask_sqlalchemy import SQLAlchemy
from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField
from datetime import datetime

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///site.db'  # Corrected URI
app.config['SECRET_KEY'] = 'your_secret_key'
db = SQLAlchemy(app)

class Post(db.Model):  # Corrected class name
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    content = db.Column(db.String, nullable=False)
    date = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    def update(self, title, content):
        self.title = title
        self.content = content
        db.session.commit()

class ContactForm(FlaskForm):
    title = StringField('Title')
    content = StringField('Content')
    submit = SubmitField('Submit')

@app.route('/')
def home():
    posts = Post.query.all()
    return render_template('home.html', posts=posts)

@app.route('/edit/<int:post_id>', methods=['GET', 'POST'])
def edit_post(post_id):
    post = Post.query.get_or_404(post_id)
    form = ContactForm(obj=post)

    if form.validate_on_submit():
        post.update(form.title.data, form.content.data)
        return redirect('/')
    
    return render_template('edit_post.html', form=form, post=post)

@app.route('/about')
def about():
    return render_template('about.html')

if __name__ == '__main__':
    app.run(debug=True)
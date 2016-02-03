from flask import *
from functools import wraps

app = Flask(__name__)

app.secret_key = "adsasc"

@app.route('/')
def homepage():
    return render_template('home.html')

@app.route('/upload')
def upload():
    return render_template('upload.html')
    
@app.route('/logout')
def logout():
    session.pop('logged_in', None)
    return redirect(url_for('homepage'))
    
@app.route('/log', methods=["GET", "POST"])
def log():
    error = None
    if request.method == "POST":
        if request.form['username'] != "b_browne" or request.form['password'] != "admin":
            error = "Access not permitted"
        else:
            session['logged_in'] = True
            return redirect url_for('upload')
    return render_template('log.html', error = error)

if __name__ == "__main__":
    app.run()

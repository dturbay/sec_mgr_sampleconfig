from bottle import auth_basic, route, run

def check(user, pw):
  if user == 'user2' and pw == 'password2':
    return True
  else:
    return False

@route('/auth')
@auth_basic(check)
def hello():
  return "Hello World!"

run(host='0.0.0.0', port=4444, debug=True)


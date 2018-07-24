from bottle import auth_basic, route, run

def check(user, pw):
  if (user == 'user2' and pw == 'password2') or (user == 'user1' and pw == 'password1'):
    return True
  else:
    return False

@route('/auth')
@auth_basic(check)
def auth():
  return "Hello World!"


# resources

def parametrized_check(predefined_user, predefined_password):
  def check(user, password):
    return predefined_user == user and predefined_password == password
  return check


@route('/resource1')
@auth_basic(parametrized_check('user1', 'password1'))
def resource1():
  return "Hello resource1!"

@route('/resource2')
@auth_basic(parametrized_check('user2', 'password2'))
def resource2():
  return "Hello resource2!"



run(host='0.0.0.0', port=4444, debug=True)


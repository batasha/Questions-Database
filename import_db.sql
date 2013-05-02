CREATE TABLE users (

  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL

);


CREATE TABLE questions (

  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY(author_id) REFERENCES users(id)
);


CREATE TABLE question_followers (

  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
);


CREATE TABLE replies (

  id INTEGER PRIMARY KEY,
  body TEXT NOT NULL,
  subject_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,
  parent_id INTEGER,

  FOREIGN KEY(subject_id) REFERENCES questions(id),
  FOREIGN KEY(author_id) REFERENCES users(id),
  FOREIGN KEY(parent_id) REFERENCES replies(id)
);


CREATE TABLE question_likes (

  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
);

INSERT INTO users ('fname', 'lname')
VALUES ('Ke', 'Li'),
       ('Natasha', 'Badillo');

INSERT INTO questions ('title', 'body', 'author_id')
VALUES (
  'Monty Python Question',
  'What is the airspeed velocity of an unladen swallow?',
  1
);

INSERT INTO replies ('body', 'subject_id', 'author_id')
VALUES (
  'What do you mean?  An African or European swallow?',
  1,
  2
);

INSERT INTO replies('body', 'subject_id', 'author_id', 'parent_id')
VALUES (
  "I don't know that",
  1,
  1,
  1
);

INSERT INTO question_followers('user_id', 'question_id')
VALUES (1, 1), (2, 1);

INSERT INTO question_likes('user_id', 'question_id')
VALUES (1, 1), (2, 1);
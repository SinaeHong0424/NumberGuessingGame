#!/bin/bash

# Database connection
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Request username
echo "Enter your username:"
read USERNAME

# Check if the user exists in the database
USER_RESULT=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_RESULT ]]
then
  # New user case
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user into the database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played) VALUES('$USERNAME', 0)")
else
  # Returning user case
  IFS='|' read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_RESULT"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the guessing game
echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0

while true
do
  read GUESS

  # Validate input as integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  GUESS_COUNT=$((GUESS_COUNT + 1))

  # Compare guess to secret number
  if [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Update games played and best game for user
    if [[ -z $BEST_GAME || $GUESS_COUNT -lt $BEST_GAME ]]
    then
      UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game=$GUESS_COUNT WHERE username='$USERNAME'")
    fi
    UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played=games_played+1 WHERE username='$USERNAME'")
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

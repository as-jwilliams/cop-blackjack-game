import json
import random

VALUES = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
SUITS = ['Hearts', 'Diamonds', 'Clubs', 'Spades']

def create_deck():
    return [{'value': value, 'suit': suit} for value in VALUES for suit in SUITS]

def deal_card(deck):
    return deck.pop(random.randint(0, len(deck) - 1))

def calculate_hand_value(hand):
    value = 0
    ace_count = 0
    for card in hand:
        if card['value'] in ['J', 'Q', 'K']:
            value += 10
        elif card['value'] == 'A':
            ace_count += 1
            value += 11
        else:
            value += int(card['value'])

    while value > 21 and ace_count:
        value -= 10
        ace_count -= 1

    return value

def handler(event, context):
    action = event['action']
    player_hand = event.get('player_hand', [])
    dealer_hand = event.get('dealer_hand', [])
    deck = event.get('deck', create_deck())

    if action == 'start':
        player_hand = [deal_card(deck), deal_card(deck)]
        dealer_hand = [deal_card(deck), deal_card(deck)]
    elif action == 'hit':
        player_hand.append(deal_card(deck))
    elif action == 'stay':
        while calculate_hand_value(dealer_hand) < 17:
            dealer_hand.append(deal_card(deck))

    player_value = calculate_hand_value(player_hand)
    dealer_value = calculate_hand_value(dealer_hand)

    result = ""
    if action == 'stay':
        if player_value > 21:
            result = "Player busts! Dealer wins."
        elif dealer_value > 21:
            result = "Dealer busts! Player wins."
        elif player_value > dealer_value:
            result = "Player wins!"
        elif player_value < dealer_value:
            result = "Dealer wins!"
        else:
            result = "It's a tie!"

    return {
        'statusCode': 200,
        'body': json.dumps({
            'player_hand': player_hand,
            'dealer_hand': dealer_hand,
            'deck': deck,
            'player_value': player_value,
            'dealer_value': dealer_value,
            'result': result
        })
    }

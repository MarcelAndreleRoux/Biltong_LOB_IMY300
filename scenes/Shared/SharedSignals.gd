extends Node

# Player Signals
signal item_pickup
signal pickup_item
signal item_throw
signal shadow_update

# Door Signals
signal doorState

# now go to any script you want the signal to emit from "SharedSignal.MySignal.emit()" you can add anything you need to 
# send though inside the brackets

# Go to the the script you want to connect the signal to and use "SharedSignal.MySignal.connect(some_func)" in the ready
# and then use the 'some_func' to access the contents and to do someting when the signal is emiited

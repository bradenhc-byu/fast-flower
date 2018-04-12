# Brainstorming for Final Project
## CS 462 - Distributed Systems
Blaine Backman  
Braden Hitchcock  
Jonathon Meng   

### Fast Flower Delivery

**Underlying Data Structures**
- DeliveryRequest
- Driver
- Store

**Pico Types**
- Driver Pico
- Store Pico

**Events**

| Domain    | Type                      | Description                                   |
|-----------|---------------------------|-----------------------------------------------|
| driver    | new_driver                | creates a new driver                          |
|           | driver_added              | upon successfully creating a new driver       |
|           | remove_driver             | removes a driver                              |
|           | driver_removed            | upon successfully removing a driver           |
|           | update_profile            | changes a driver's profile information        |
|           | profile_updated           | upon successfully updating profile info       |
|           | register_request          | requests driver registration with a store     |
|           | register_request_accepted | upon approving a driver registration request  |
|           | register_request_denied   | upon denying a driver registration request    |
| delivery  | new_request               | creates a new delivery request                |
|           | request_created           | upon successfully creating a new delivery req.|
|           | cancel_request            | cancels a previously created request          |
|           | accept_request            | when a driver accepts a request               |
|           | finish_delivery           | request has been successfully delivered       |

**API Functions**

| Ruleset           | Function          | Result                                            |
|-------------------|-------------------|---------------------------------------------------|
| driver_manager    | drivers           | a list of drivers registered with the manager     |
| request_storage   | delivery_requests | a list of current delivery requests (filterable)  |

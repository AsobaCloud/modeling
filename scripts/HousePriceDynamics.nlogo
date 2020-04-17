;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    Modeling House Price Dynamics in an Urban/Suburban Market    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals
[
  housingDemand

  displaced-renter
  displaced-owner
]

; agents
breed [banks bank]
banks-own
[
  myMortgages
  incomeFromHouses
]

breed [households household]
households-own
[
  income    ; period income
  baseIncome ; base income - used for restoring income when re-employed
  myHouses   ; which houses do I own; first in the list is the own I occupy. the rest are the ones I own and perhaps rent.
  timeInHouse ;
  investmentCapital
  is-employed ; is this household employed
  is-immigrant?

  eligible-buyers
  gentrifiers
]

breed [houses house]
houses-own
[
  has-owner
  updateMortgage
  is-occupied    ; does someone live here
  is-rental      ; am I a rental

  price  ; current market value of house
  purchase-price; purchase price - this is what mortgage payments are based off of
  is-owned;todo keep track if house is owned or not
  mortgageCost  ; tick mortgage cost
  rent      ; tick rent cost

  missedPaymentCount ; count number of missed payments
  is-cooldown?
]

breed [mortgages mortgage]
mortgages-own
[
  which-owner
  which-house
  which-bank

  purchasePrice
]

;initialization
to initialize

  clear-all
  random-seed 8675309
  ;agents
  setup-houses
  setup-households

  setup-banks
  setup-mortgages

  ;plots
  setup-average-house-price-plot
  update-average-house-price-plot



  reset-ticks
end

to go

  set-immigrants
  set-immigrants
  immigration
  houselords
  displaced-buyers
  imm-renters
  remove-homeless

  update-housing-price-info
  update-available-capital
  update-households
  buy-investment-houses
  update-available-capital
  ;update-households
  update-mortgages
  sell-investment-houses

  tick

  update-average-house-price-plot
  update-mortgage-plot
  update-ownership-plot


  ;update-average-location
  ;update-housing-stats
  compute-bank-balances
  update-average-investment-capital
  update-interest-rate-plot
  update-savings-rate-plot
  update-bankrupt-households-plot
  update-balance-sheet-plot
  update-unemployment-plot
  update-population-count-plot




end


; procedures
to update-housing-price-info

  let tmpList []
  ask households
  [
    let tmpCount length myHouses
    set tmpList fput tmpCount tmpList
  ]

  let multiplier 1 + 3 * (mean tmpList - housingDemand) / 10

  set housingDemand mean tmpList
  print word "housing multipler" multiplier


  ask houses
  [
    if random 100 < 5
    [
      ;if is-occupied = 0 ; todo: do this but make the adjustment only for un-owned houses.
      ;[
      ;set mortgageCost 0.01 +  price * interest-rate / 60
      set mortgageCost (((1 - downpayment-amount) * price * interest-rate) / 360 )
      set rent  price * rental-fraction
      ;]
    ]

    if random 100 < 20
    [
      ;print word "1 " price
      set price (price * multiplier * multiplier * multiplier)
      ;print word "2 " price
    ]

    ifelse is-rental = 1
    [
      set color rgb (55 + (200 * (price - min-price) / (max-price - min-price))) 0 0
    ]
    [
      set color rgb 0 (55 + (200 * (price - min-price) / (max-price - min-price))) 0
    ]

    ifelse missedPaymentCount > 3
        [
          set size 2.0
          set color pink

    ]
    [
      ifelse is-rental = 1
      [
        set color rgb (55 + (200 * (price - min-price) / (max-price - min-price))) 0 0
      ]
      [
        set color rgb 0 (55 + (200 * (price - min-price) / (max-price - min-price))) 0
      ]
      set size 1.0
    ]
  ]
end

to sell-investment-houses
  ;ask households whose investment capital is negative to sell a house
  ask households with [investmentCapital < 0 and length myHouses > 1]
  [
    if random 100 < 50
    [
      ;sell a house
      ;print "Selling a house"
      let tmpHouses but-first myHouses
      let listToSell houses with [member? self tmpHouses]   ; find houses that are in the household's list
                                                            ;print listToSell
                                                            ;print count houses with [updateMortgage = 1]
      let tmpMyHouses []
      set tmpMyHouses myHouses
      let foreclosedHouses  listToSell with [missedPaymentCount > 3]
      ifelse count foreclosedHouses > 0
      [
        if random-float 1.0 < 0.2
        [
          ask one-of foreclosedHouses
          [
            ;find my mortgage and sell me
            let myMortgage one-of mortgages with [which-house = myself] ; find my mortgage

            ;print myMortgage
            ;print tmpMyHouses
            set tmpMyHouses remove-item (position self  tmpMyHouses) tmpMyHouses

            set missedPaymentCount 0
          ]
        ]
      ]
      [
        ask one-of listToSell
        [
          ;find my mortgage and sell me
          let myMortgage one-of mortgages with [which-house = myself] ; find my mortgage

          ;print myMortgage
          ;print tmpMyHouses
          set tmpMyHouses remove-item (position self  tmpMyHouses) tmpMyHouses

        ]
      ]
      ;print "Done Selling a house"
      set myHouses tmpMyHouses
    ]
  ]
end

to update-households

  ask households with [investmentCapital >= 0]
  [
    set color rgb 0 (100 + (155 * (income - min-income ) / (max-income - min-income))) 0
    set size 1.0
  ]

  ask households with [length myHouses > 0]
  [

    set timeInHouse (timeInHouse + 1)
    ;randomly move to a new house
    if (random mobility = 1 or ; check to see if it's time to move to a new hosue
      (investmentCapital < 0 and (length myHouses = 1))) ; or if house has become too expensive
    [
      ;;begin move to new house
      ;sell-house
      set timeInHouse 0
      let myHouse item 0 myHouses

      if ([is-rental] of myHouse = 0)
      [
        ;set [has-owner] of myHouse 0
        ask myHouse [set has-owner 0]
      ]
      ;set [is-occupied] of myHouse 0
      ask myHouse [set is-occupied 0]
      set myHouses remove-item 0 myHouses


      ;buy new house
      let housingList houses  with
      [
        count households-here = 0
      ];; assign a house to occupy

      let tmpHouse nobody

      let myRentalList housingList with [is-rental = 1 and rent < [income] of myself]

      ;; MOD: need to update this purchase list to only include houses where the mortgageCost is less than income - (sum of all other current mortgage payments)
      let myPurchaseList housingList with [is-rental = 0 and mortgageCost < [income] of myself and (price * downpayment-amount) < [investmentCapital] of myself]

      ;print count myRentalList
      ;print count myPurchaseList


      ifelse (count myPurchaseList > 0)
      [
        set tmpHouse one-of myPurchaseList
      ]
      [
        if (count myRentalList > 0)
        [
          set tmpHouse one-of myRentalList
        ]
      ]

      ;;occupy tmpHouse
      ;;show tmpHouse
      if tmpHouse != nobody [
        move-to tmpHouse



        ;;create-link-with  tmpHouse
        set myHouses  fput tmpHouse myHouses           ; add it to my list of houses. most households will have one house.

        ask item 0 myHouses
        [
          set is-occupied 1
        ]

        ;exchange mortgage
        ask mortgages with [which-owner = myself and which-house = myHouse]
        [
          set which-owner myself
          set which-house item 0 [myHouses] of which-owner
          set which-bank one-of banks
          move-to which-bank
        ]
      ]
    ]
    ;;end move to a new house


    ;;THIS IS MY ATTEMPT AT ADDING UNEMPLOYMENT FOR TICK UPDATES
    ;;adding unemployment
    let unemploymentList households with [is-employed = 0]
    ;creating a list of currently unemployed
    let employmentList households with [is-employed = 1]
    ;creating a list of the currently employed

    if (count unemploymentList < count households * unemployment)
    ;if unemployment rate is higher than the ratio of people in unemployment list
    [
      set unemploymentList n-of (count households * unemployment - count unemploymentList) households with [is-employed = 1]
      ;Find the difference between the count of unemployed households based on the lever and count of households on unemployment list
      ;in this if scenario, unemployment rate is larger than current unemployment list, so add difference to unemployment list
      ask unemploymentList
      [
        set income 0
        set is-employed 0
      ]
    ]

    if (count unemploymentList > count households * unemployment)
    [
      set employmentList n-of (count unemploymentList - count households * unemployment) households with [is-employed = 0]
      ask employmentList
      ;remove households from unemployment list if unemployment rate is less than size of unemployment list
      [
        set income baseIncome
        set is-employed 1
      ]
    ]

  ]
end

to update-mortgages

  let tmpMortgageCount count houses with [updateMortgage = 1]
  create-mortgages tmpMortgageCount
  [
    set which-house one-of houses with
    [
      updateMortgage = 1
      ;member? self myHouses = true
    ]
    set which-owner one-of households with
    [
      member? [which-house] of myself myHouses = true
    ]
    set which-bank one-of banks
    set purchasePrice (1 - downpayment-amount) * [price] of which-house
    ;set [purchase-price] of which-house purchasePrice
    let newpp purchasePrice
    ask which-house [set purchase-price newpp]
    move-to which-bank
    ;set [updateMortgage] of which-house 0  ; finished updating
    ask which-house [set updateMortgage 0]
  ]
end

to update-available-capital
  ; update available capital

  ask households
  [
    ;let totalMortgageCost [mortgageCost]
    ;set totalMortgageCost sum [mortgageCost] of myHouses
    ;let rentalIncome sum [rent] of myHouses
    let savedCapital investmentCapital
    let tmpCapital income
    if (length myHouses > 0) [
    let tmpHouse item 0 myHouses

    ifelse ( [is-rental] of tmpHouse = 0)
    [
          set tmpCapital tmpCapital - [mortgagecost] of tmpHouse

    ]
    [
        ifelse (tmpCapital - [rent] of tmpHouse > 0) [
          set tmpCapital tmpCapital - [mortgagecost] of tmpHouse][
          ask tmpHouse[
            set missedPaymentCount (missedPaymentCount + 1)]
        ]
     set tmpCapital tmpCapital - [rent] of tmpHouse
    ]

    if (length myHouses > 1)
    [
      let tmpHouses but-first myHouses
        let tmpHousesAgentset houses with [member? self tmpHouses]

      ;;;; new code here
      ;; tmpCapital calculated here for each household
      ;; if tmpCapital < 0 then for some of houses we will miss the payment of
      let my_sum_mortgage sum [mortgageCost] of tmpHousesAgentset
      let my_sum_rent sum [rent] of tmpHousesAgentset
      set tmpCapital tmpCapital + my_sum_rent
        ifelse tmpCapital - my_sum_mortgage > 0 [
          set tmpCapital tmpCapital - my_sum_mortgage
        ][

          let thouses houses with [member? self tmpHouses]
          ask thouses [
            ifelse tmpCapital - mortgageCost > 0 [
              set tmpCapital tmpCapital - mortgageCost][
              set missedPaymentCount (missedPaymentCount + 1)
            ]
          ]

        ]
      ]
;
;      ask houses with [member? self tmpHouses]   ; find houses that are in the household's list, and subtract cost
;      [
;
;        ;; MOD need to properly sum the total mortgage cost of of myHouses
;        set tmpCapital tmpCapital - sum [mortgageCost] of houses  + sum [rent] of houses
;        let housingList houses
;        ;print houses
;        ifelse tmpCapital < 0
;        [
;          set missedPaymentCount (missedPaymentCount + 1)
;        ]
;        [
;          set missedPaymentCount 0
;        ]
;      ]
;    ]

    ]

     set investmentCapital ((tmpCapital * (savings-rate / 100)) + savedCapital)

  ]
end

to buy-investment-houses
  ask households
  [
    ;randomly choose a new house to buy
    if random-float 1.0 < 0.1
    [
      ;print "buying an investment house"
      ;buy new house
      let housingList houses  with
      [
        count households-here = 0 and
        mortgagecost < (0.25 * [income] of myself) and
        price * downpayment-amount < [investmentCapital] of myself

      ];; assign a house to buy
       ;print [mortgagecost] of houses
       ;print investmentCapital
      let tmpHouse []

      ;let myPurchaseList housingList with [is-rental = 0 and mortgageCost < [income] of myself]

      if (count housingList > 0)
      [
        set tmpHouse one-of housingList ;if there are houses available, choose one to buy
                                        ;;add house to my list
                                        ;print "tmpHouse"
                                        ;print tmpHouse
        set myHouses  lput tmpHouse myHouses           ; add it to my list of houses. most households will have one house.

        ;adjust capital
        ;set [is-rental] of tmpHouse 1
        ask tmpHouse [set is-rental 1]
        ;set investmentCapital (investmentCapital - ([mortgageCost] of tmpHouse))
        set investmentCapital (investmentCapital - (downpayment-amount * [price] of tmpHouse))
      ]
      ;print "done buying an investment house"
    ]
  ]
end

to setup-mortgages
  set-default-shape mortgages "loan"
  create-mortgages count houses with [is-occupied = 1]
  ask mortgages
  [
    let myHouse one-of houses with [is-occupied = 1 and updateMortgage = 1]
    set which-owner one-of households with
    [
      item 0 myHouses = myHouse
    ]

    set which-house item 0 [myHouses] of which-owner
    set which-bank one-of banks
    set purchasePrice [price * downpayment-amount] of which-house
    ;set [updateMortgage] of which-house 0
    ask which-house [set updateMortgage 0]
    move-to which-bank
    set color green
  ]
end

to setup-houses
  ask patches
  [
    set pcolor black
  ]
  set-default-shape houses "house"
  ;set-default-shape patches "house"

  let houseCount ceiling (initial-density * world-width * world-height / 100)
  ;print houseCount
  create-houses houseCount
  ask houses
  [
    set price (min-price + random (max-price - min-price))
    set is-occupied 0
    ;set mortgageCost 0.01 + price * interest-rate / 50
    set mortgageCost (((1 - downpayment-amount) * price * interest-rate) / 360 )

    if random-float 100.0 < rental-density
      [
        set is-rental 1
        set rent  price * rental-fraction

    ]
    let tmpPrice price
    move-to one-of patches with [count (houses-here) = 0 and abs (pycor / world-height - ((tmpPrice - min-price) / (max-price - min-price))) < .1]
    ;move-to one-of patches with [count (houses-here) = 0 ]
    ifelse is-rental = 1
    [
      set color orange + 2 ; color if house is a rental
      set shape "house efficiency"
    ]
    [
      set color lime + 2 ; color if house is owner-occupied
      set shape "house-2"
    ]
    set size 1.5 ; dont draw the house agent
    set updateMortgage 1
  ]

end

to setup-households
  set-default-shape households "household indicator"

  let num-households (count houses * percent-occupied / 100);
  create-households num-households
  [
    set income (random (max-income - min-income) + min-income)
    set is-employed 1
    set baseIncome income
    set investmentCapital (random (max-start-savings - min-start-savings) + min-start-savings)
    set is-immigrant? false

    set myHouses []


    let housingList houses  with
        [
          count households-here = 0
    ];; assign a house to occupy

    let tmpHouse []

    let myRentalList housingList with [is-rental = 1 and rent < [income] of myself]
    let myPurchaseList housingList with [is-rental = 0 and mortgageCost < [income] of myself]

    ;print count myRentalList
    ;print count myPurchaseList

    ifelse (count myPurchaseList > 0)
    [
      set tmpHouse one-of myPurchaseList
    ]
    [
      if (count myRentalList > 0)
      [
        set tmpHouse one-of myRentalList
      ]
    ]
    if tmpHouse != [] [
      ;;occupy tmpHouse
      move-to tmpHouse  ; here is where we should deal with homeless households
      set timeInHouse random mobility
      ;;create-link-with  tmpHouse
      set myHouses  lput tmpHouse myHouses           ; add it to my list of houses. most households will have one house.

      ask item 0 myHouses
      [
        set is-occupied 1
      ]

      ;adjust capital
      let houseType [is-rental] of tmpHouse

      ifelse houseType = 1
      [
        set investmentCapital ((investmentCapital - [rent] of tmpHouse) * (savings-rate / 100))
      ]
      [
        set investmentCapital ((investmentCapital - [mortgageCost] of tmpHouse) * (savings-rate / 100) )
      ]
      ;give self a color
      ;set color rgb 0 (100 + (155 * (income - min-income ) / (max-income - min-income))) 0
      set color green
      ;set color scale-color green income min-income max-income
    ]

    ;; THIS IS MY ATTEMPT AT ADDING UNEMPLOYMENT FROM TURN 0
    ;now assign employment status
    let unemploymentList n-of (num-households * unemployment) households
    ask unemploymentList
      [
        set income 0
        set is-employed 0
    ]
  ]

end

to setup-banks
  set-default-shape banks "bank"
  create-banks num-banks
  [
    set color white
    move-to one-of patches with
      [count (turtles-here) = 0]
    set size 1.5
  ]
end

to compute-bank-balances
  ask banks
  [
    let delta 0
    ask mortgages with [which-bank = myself]
    [
      if [missedPaymentCount] of which-house > 0
      [
        set delta (delta + (([price] of which-house) - purchasePrice))
      ]
    ]
    print delta
    set incomeFromHouses delta
    ifelse (delta < 0)
    [
      set color red
    ] ; else
    [
      set color yellow
    ]
  ]
end


to set-immigrants

  ask houses [set is-cooldown? false] ; new houses-own variable to control for houses already bought on a tick

  set-default-shape households "household indicator"

  ;create-households immigrant-number-every-tick
  create-households (count households) * immigration-rate
  [
    set income (random (max-income - min-income) + min-income)
    set is-employed 1
    set baseIncome income
    set investmentCapital (random (max-immigrant-savings - min-immigrant-savings) + min-immigrant-savings)
    set is-immigrant? true
    set myHouses []
  ]
end

to immigration

  ask households with [is-immigrant? = true]
  [
    let housingList houses with [is-occupied = 0 ]

    if count housingList > 0 ;;rh_ all of the below can enter the gentrification function with an ifelse
    [
      let tmpHouse []
      let myPurchaseList housingList with [is-rental = 0 and mortgageCost < [income] of myself and is-cooldown? = false]
      let myRentalList housingList with [is-rental = 1 and rent < [income] of myself]

      ;print count myPurchaseList
      ;print count myRentalList

      ifelse (count myPurchaseList > 0)
      [
        set tmpHouse one-of myPurchaseList
      ]
      [
        if (count myRentalList > 0)
        [
          set tmpHouse one-of myRentalList
        ]
      ]

      if tmpHouse != [] [
        ask tmpHouse [set is-cooldown? true]
        ;;occupy tmpHouse
        move-to tmpHouse
        set timeInHouse random mobility
        set myHouses lput tmpHouse myHouses           ; add it to my list of houses. most households will have one house.

        ask item 0 myHouses
        [
          set is-occupied 1
        ]
        ;adjust capital
        let houseType [is-rental] of tmpHouse

        ifelse houseType = 1
        [
          set investmentCapital ((investmentCapital - [rent] of tmpHouse) * (savings-rate / 100))
        ]
        [
          set investmentCapital ((investmentCapital - [mortgageCost] of tmpHouse) * (savings-rate / 100) )
        ]
        ;give self a color
        ;set color rgb 0 (100 + (155 * (income - min-income ) / (max-income - min-income))) 0
        set color green
        ;set color scale-color green income min-income max-income
      ]
    ]
  ]

end

to houselords

  ask households
  [
  set eligible-buyers 0
  set gentrifiers 0
  ]
  set displaced-renter []
  set displaced-owner []

  let housingList houses with [ is-occupied = 1]

  if count housingList > 0
  [
    ask households
    [ let my-Houses myHouses
      ;if the hosehold is a wealthy house owner or immigrant or only an eligible renter
      ifelse length myHouses > 1 and investmentCapital > downpayment-amount * mean [price] of houses and income - sum [mortgageCost] of houses with [ member? self my-Houses = true]  > mean [mortgageCost] of houses
      [set eligible-buyers 1]
      [ifelse is-immigrant? = true and investmentCapital > downpayment-amount * mean [price] of houses and income > mean [mortgageCost] of houses
        [set eligible-buyers 1]
        [if is-immigrant? = true and income > mean [rent] of houses and investmentCapital < downpayment-amount * mean [price] of houses
          [set gentrifiers 1]
        ]
      ]
    ]
  ]

  if count households with [eligible-buyers = 1] > 0
  [
    ask households with [eligible-buyers = 1]
    [
      let myinvestmentCapital investmentCapital
      let my-Houses myHouses
      let potential-buys []

      ask houses
      [
        if (downpayment-amount * price) + mortgageCost < myinvestmentCapital and member? self my-Houses = false and is-cooldown? = false  and count households-here > 0
        [set potential-buys fput self potential-buys]
      ]
        ;bid on one-of potential-houses
      if  potential-buys != []
      [
        let bid item 0 potential-buys
        let bool false

        ifelse [purchase-price] of bid > 0
        [set bool [price] of bid - [purchase-price] of bid / ([purchase-price] of bid) > return-expectation]
        [set bool [price] of bid > return-expectation]

       if bool = true
        [
          ask bid [set updateMortgage 1  set is-cooldown? true] ; updating Mortgage
          set myHouses lput bid myHouses                          ; buy the house
          ;set investmentCapital ((investmentCapital - [mortgageCost] of bid) * (savings-rate / 100) )   ; adjust capital
          ask bid [set is-cooldown? true]

          if is-immigrant? = true ;if buyer is an immigrant
          [
           ask bid [set is-rental 0]
           let tenant [one-of households-here] of bid
           ;let my-Houses [myHouses] of tenant

            ifelse member? bid [myHouses] of tenant = true            ; if the tenant is the owner prob
            [
            ask tenant [set myHouses remove-item 0 myHouses]
              ifelse  [myHouses] of tenant != []        ; if it wasn't the owner's only house
              [
                ask tenant
                [
                  move-to item 0 myHouses ; telling tenant to move to one of their other houses
                  ask item 0 myHouses [set is-rental 0] ; how to make it work?
                ]
              ]
              [
              set displaced-owner fput tenant displaced-owner  ; if that was the tenant's only house -> displaced

            ]
            ]
            [set displaced-renter fput tenant displaced-renter] ; if tenant was a renter
           move-to bid
          ]
        ]
      ]
    ]
  ]
end

to displaced-buyers

  ask households with [ member? self displaced-owner = true and investmentCapital > downpayment-amount * mean [price] of houses and income > mean [mortgageCost] of houses]
  [
    set eligible-buyers 1

    let bid one-of houses with [is-rental = 1 and downpayment-amount * price < [investmentCapital] of myself and mortgageCost < [income] of myself and is-cooldown? = false]

    if bid != nobody
      [
        let bool false
        ifelse [purchase-price] of bid > 0
        [set bool [price] of bid - [purchase-price] of bid / ([purchase-price] of bid) > return-expectation]
        [set bool [price] of bid > return-expectation]

       if bool = true
        [
          ask bid [set updateMortgage 1 set is-rental 0 set is-cooldown? true] ; updating Mortgage
          set myHouses lput bid myHouses ; "buys" the house ( adding the house to myHouses )
          set investmentCapital ((investmentCapital - [mortgageCost] of bid) * (savings-rate / 100) )
          let tenant [one-of households-here] of bid

          set displaced-renter fput tenant displaced-renter
          if is-immigrant? = true and length myHouses = 1  and count [households-here] of bid = 0 [  move-to bid  ]
        ]
      ]
    ]
end

to imm-renters

  let rents houses with [is-rental = 1 and is-occupied = 0]
  ask households with [gentrifiers = 1 ]
  [
  if count rents > 0
   [
  let my-affordable-rents rents with [rent < [income] of myself]
  let my-rent item 0 my-affordable-rents
  set myHouses fput my-rent myHouses
  move-to my-rent
  set investmentCapital ((investmentCapital - [rent] of my-rent) * (savings-rate / 100))
  set rents remove my-rent rents
  ]
]

  ask households with [member? self displaced-renter = true]
  [
    if count rents > 0
    [
  let my-affordable-rents rents with [rent < [income] of myself]
  let my-rent item 0 my-affordable-rents
  set myHouses fput my-rent myHouses
  move-to my-rent
  set investmentCapital ((investmentCapital - [rent] of my-rent) * (savings-rate / 100))
  set rents remove my-rent rents
  ]
  ]

end


to remove-homeless
  ask households with [length myHouses = 0] [
    die
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;plots




to setup-average-house-price-plot
  set-current-plot "average house price"
  set-plot-y-range  0 (ceiling max [mortgageCost] of houses)
end

to update-average-house-price-plot
  set-plot-y-range 50 150
  set-current-plot "average house price"
  let myMean mean [price] of houses with [is-occupied = 1]
  set-current-plot-pen "myMean"
  plot myMean
  print "mean house price"
  print myMean
end

to update-mortgage-plot
  set-current-plot "Average Mortgage and Rent"
  set-current-plot-pen "Average Mortgage"
  plot mean [mortgageCost] of houses with [is-occupied = 1]
  set-current-plot-pen "Average Rent"
  plot mean [rent] of houses with [is-occupied = 1]


end

to update-unemployment-plot
  set-current-plot "Unemployment Rate"
  set-current-plot-pen "unemploymentRate"
  plot (count households with [is-employed = 0]) * 100 / (count households)
  set-plot-y-range  0 100

end


; to update-average-location
;  set-current-plot "average loc"
;  let myMean mean [ycor] of households
;  set-current-plot-pen "myLoc"
;  plot myMean
;end

to update-average-investment-capital
  set-current-plot "Average Household Investment Capital"
  let myMean median [investmentCapital] of households
  set-current-plot-pen "myCapital"
  plot myMean
  let myMean2 median [income] of households
  set-current-plot-pen "myIncome"
  plot myMean2
end

to update-ownership-plot
  set-current-plot "owner occupied and rental homes"
  let myOwnedHouses ((count houses with [is-occupied = 1 and is-rental = 0]) / (count houses)) * 100
  set-current-plot-pen "Owned Houses"
  plot myOwnedHouses
  let myRentedHouses ((count houses with [is-occupied = 1 and is-rental = 1]) / (count houses)) * 100
  set-current-plot-pen "Rented Houses"
  plot myRentedHouses
  let occupiedHouses ((count houses with [is-occupied = 1]) / (count houses)) * 100
  set-current-plot-pen "Occupied Houses"
  plot occupiedHouses
  ;print "owned and rented"
  ;print word myOwnedHouses myRentedHouses

end

to update-housing-stats
  set-current-plot "mean number of investment houses owned"
  set-plot-y-range  0 15
  let tmpList []
  ask households
    [
      let tmpCount length myHouses
      set tmpList fput tmpCount tmpList
  ]
  print word "average houses owned:" mean tmpList
  set-current-plot-pen "count"
  plot (mean tmpList - housingDemand) * 10
  ;plot (mean tmpList)
end

to update-interest-rate-plot
  set-current-plot "Interest Rate"
  set-plot-y-range  0 15

  plot interest-rate

end

to update-population-count-plot
  set-current-plot "Population"
  set-plot-y-range 0 1000
  let popCount count households
  plot popCount


end

to update-savings-rate-plot
  set-current-plot "Savings Rate"
  set-plot-y-range 0 25

  plot savings-rate

end

to update-bankrupt-households-plot
  set-current-plot "Affordability"
  let bankrupthouseholdsCount ((count households with [investmentCapital < 0]) / count households) * 100

  plot bankrupthouseholdsCount
  set-plot-y-range  0 100

end


to update-balance-sheet-plot
  ;; would like to make this more useful - rather than count, would like to see mean/median bank income
  set-current-plot "Average Bank Income"
  ;let solventBankCount count banks with [incomeFromHouses > 0]
  let bankIncome mean [incomeFromHouses] of banks
  ;plot solventBankCount
  set-current-plot-pen "meanIncome"
  plot bankIncome
  let bankIncomeTotal sum [incomeFromHouses] of banks
  set-current-plot-pen "totalIncome"
  plot bankIncomeTotal
  ;set-plot-y-range  -1 (ceiling max [incomeFromHouses] of banks)
  set-plot-y-range  0 100
end



@#$#@#$#@
GRAPHICS-WINDOW
535
18
1110
594
-1
-1
17.2
1
10
1
1
1
0
0
0
1
0
32
0
32
1
1
1
months
30.0

SLIDER
8
615
180
648
initial-density
initial-density
1
99
86.0
0.1
1
%
HORIZONTAL

BUTTON
5
47
107
80
NIL
initialize
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
6
231
110
269
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
116
231
220
269
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
7
18
157
40
Simulation Setup
16
0.0
1

SLIDER
9
655
181
688
rental-density
rental-density
0
100
7.0
1
1
%
HORIZONTAL

SLIDER
4
108
184
141
interest-rate
interest-rate
.25
15
3.5
0.25
1
%
HORIZONTAL

PLOT
242
18
527
229
average house price
months
Amt in $
0.0
10.0
50.0
150.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" ""
"myMean" 1.0 0 -16777216 true "" ""

SLIDER
8
695
180
728
percent-occupied
percent-occupied
0
100
100.0
1
1
%
HORIZONTAL

INPUTBOX
195
646
274
706
min-price
350.0
1
0
Number

INPUTBOX
278
646
366
706
max-price
550.0
1
0
Number

INPUTBOX
370
646
457
706
max-income
100.0
1
0
Number

INPUTBOX
194
712
289
772
num-banks
4.0
1
0
Number

INPUTBOX
294
710
388
770
rental-fraction
0.01
1
0
Number

PLOT
242
435
529
590
owner occupied and rental homes
months
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Owned Houses" 1.0 0 -13345367 true "" ""
"Rented Houses" 1.0 0 -2674135 true "" ""
"Occupied Houses" 1.0 0 -7500403 true "" ""

INPUTBOX
462
646
547
706
min-income
10.0
1
0
Number

SLIDER
7
735
183
768
mobility
mobility
0
1200
755.0
1
1
NIL
HORIZONTAL

TEXTBOX
196
614
346
634
Economic Levers
16
0.0
1

TEXTBOX
8
87
158
107
Run
16
0.0
1

PLOT
7
415
207
536
Interest Rate
months
IR %
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

TEXTBOX
7
592
653
626
____________________________________________________________________________________________\n
11
0.0
1

PLOT
1113
172
1413
324
Affordability
months
% bankrupt
0.0
0.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
814
795
1116
952
Average Bank Income
months
Amt in $
0.0
0.0
0.0
10.0
true
true
"" ""
PENS
"meanIncome" 1.0 0 -16777216 true "" ""
"totalIncome" 1.0 0 -7500403 true "" ""

SLIDER
4
148
184
181
rental-density
rental-density
0
100
7.0
1
1
NIL
HORIZONTAL

SLIDER
3
188
183
221
savings-rate
savings-rate
0
40
10.0
1
1
%
HORIZONTAL

PLOT
243
238
527
432
Average Mortgage and Rent
months
Amt in $
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Average Mortgage" 1.0 0 -16777216 true "" ""
"Average Rent" 1.0 0 -4699768 true "" ""

PLOT
1113
18
1412
168
Average Household Investment Capital
months
Amt in $
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"myCapital" 1.0 0 -16777216 true "" ""
"myIncome" 1.0 0 -7500403 true "" ""

PLOT
7
277
210
409
Savings Rate
months
%
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

INPUTBOX
390
710
518
770
downpayment-amount
0.2
1
0
Number

INPUTBOX
318
778
436
838
max-start-savings
500.0
1
0
Number

INPUTBOX
194
778
316
838
min-start-savings
75.0
1
0
Number

SLIDER
552
680
708
713
unemployment
unemployment
0
1
0.15
0.01
1
NIL
HORIZONTAL

PLOT
1113
488
1415
637
Unemployment Rate
months
Rate %
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"unemploymentRate" 1.0 0 -7500403 true "" ""

MONITOR
813
649
972
694
unemployment-percent
count households with [is-employed = 0] / count households
3
1
11

SLIDER
551
646
785
679
immigrant-number-every-tick
immigrant-number-every-tick
0
50
50.0
1
1
NIL
HORIZONTAL

INPUTBOX
193
843
316
903
min-immigrant-savings
50.0
1
0
Number

INPUTBOX
318
843
436
903
max-immigrant-savings
500.0
1
0
Number

MONITOR
814
697
1117
742
NIL
count households with [length myHouses = 0]
17
1
11

MONITOR
1068
648
1200
693
immigrant-percent
count households with [is-immigrant? = true] / count households
3
1
11

MONITOR
814
746
1110
791
NIL
count households with [is-immigrant? = true]
17
1
11

MONITOR
976
648
1064
693
free houses
count houses with [ count households-here = 0 ]
17
1
11

PLOT
1113
328
1413
485
Population
months
population
0.0
10.0
0.0
1000.0
true
false
"" ""
PENS
"default" 1.0 0 -7500403 true "" ""

SLIDER
9
775
184
808
immigration-rate
immigration-rate
0
0.1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
10
825
183
858
return-expectation
return-expectation
0
0.1
0.02
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model focuses on the housing price dynamics of a given local housing market.
The goal is to simulate how households make housing decisions (rent vs own, and if own, buy additional houses for rental income), and how those decisions are influenced by various economic levers, including price of debt.

## HOW TO USE IT

There are three "prime" levers, interest rate, savings rate, and percent of houses that are rentals.  Interest rate corresponds to the rate of interest homeowners and real estate investors will pay for a mortgage.  Savings rate corresponds to the percent of income each household will save as investment capital for home buying.  Rental Density refers to the percent of houses that are only used as rental investment properties and are not occupied by owner.

Below the prime levers, you'll see a comprehensive section of levers that allow you to set max/min income, max/min savings, and much more

For simplicity, all houses are assumed to be single family houses

## THINGS TO NOTICE

There are three types of buildings that will appear within the world.  Two of them represent houses that are rentals and houses that are owner occupied - rentals being the smaller of the two house shapes.  While initially the owner occupied houses are lime green while the rentals are orange, colors will shift if the the owner of the house falls behind with their mortgage payments.  If a household (or owner of a rental house) has more than 3 missed payments, they get foreclosed and the house turns pink.  If an occupied rental house gets foreclosed, the renter may remain in the house.

A third type of building are banks - households take out mortgage loans from banks when buying both primary residence and investment property, while banks keep those loans on their balance sheet.  Banks remain solvent as long as the total income from mortgage payments per tick is greater than 0.  The solvency of individual loans is reflected in the tiny dollar bill on the top right of the bank.  If green, the mortgage payments are current.  If red, foreclosure is coming or has already come.

If a rental or owner occupied house is actually occupied by a household, there will be a small green dot in the top left corner of the house.  The shade of green of the dot is based on the amount of savings (aka investment capital) that the household has - the higher their relative wealth, the darker the shade of green.  

Lastly, there is a mobility lever - this is what determines how willing and ready each household is to move to a new house for their primary residence if/when they can afford to do so.

## THINGS TO TRY

Try different combinations of the economic levers to get a sense of how various monetary and demographic factors influence housing demand, average house prices, and average rental prices, and what "affordable" looks like to the households of this sim world.

Also, try playing around with the mobility lever to assess the market impact of the housing "turnover" rate.

## EXTENDING THE MODEL

The main model output I want to observe is, given observer-modified lever settings, the change in median home price over time.  I would also want to see

* The impact of available supply AND “affordability” on demand and on price
* The concept of “available space” for building new units within the environment, as well as a rate of construction of new units (ie, X # of units of Y #of bedrooms are introduced every Z turns)
* Introduce immigration and emigration - evicted households leave the area, replaced by new immigrants who may or may not be economically similar with existing residents (this allows modeling of gentrification)

## NETLOGO FEATURES

To ensure fairness, the agents should run in random order. Agentsets in NetLogo are always in random order, so no extra code is needed to achieve this.

## RELATED MODELS

* Housing Market Model (Dr. Anamaria Berea et al)


## CREDITS AND REFERENCES

This model leverages concepts introduced in other housing market models such as: 

Sara Ustvedt's "An Agent-Based Model of a Metropolitan Housing Market" from the Norwegian University of Science and Technology https://pdfs.semanticscholar.org/6455/9964ef3581aea85f4212bbdccecd6c45ce65.pdf

Jaiqi Ge's "Endogenous rise and collapse of housing price: An agent-based model of the housing market" https://www.sciencedirect.com/science/article/pii/S0198971516303714

and Oswald T J Devisch et al's "An Agent-Based Model of Residential Choice Dynamics in Nonstationary Housing Markets" https://journals.sagepub.com/doi/abs/10.1068/a41158?journalCode=epna
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bank
false
0
Polygon -7500403 true true 30 120 150 60 270 120
Rectangle -7500403 true true 45 135 75 225
Rectangle -7500403 true true 90 135 120 225
Rectangle -7500403 true true 135 135 165 225
Rectangle -7500403 true true 180 135 210 225
Rectangle -7500403 true true 225 135 255 225
Rectangle -7500403 true true 45 240 255 255
Rectangle -7500403 true true 30 255 270 270

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dollar bill
false
0
Rectangle -7500403 true true 15 90 285 210
Rectangle -1 true false 30 105 270 195
Circle -7500403 true true 120 120 60
Circle -7500403 true true 120 135 60
Circle -7500403 true true 254 178 26
Circle -7500403 true true 248 98 26
Circle -7500403 true true 18 97 36
Circle -7500403 true true 21 178 26
Circle -7500403 true true 66 135 28
Circle -1 true false 72 141 16
Circle -7500403 true true 201 138 32
Circle -1 true false 209 146 16
Rectangle -16777216 true false 64 112 86 118
Rectangle -16777216 true false 90 112 124 118
Rectangle -16777216 true false 128 112 188 118
Rectangle -16777216 true false 191 112 237 118
Rectangle -1 true false 106 199 128 205
Rectangle -1 true false 90 96 209 98
Rectangle -7500403 true true 60 168 103 176
Rectangle -7500403 true true 199 127 230 133
Line -7500403 true 59 184 104 184
Line -7500403 true 241 189 196 189
Line -7500403 true 59 189 104 189
Line -16777216 false 116 124 71 124
Polygon -1 true false 127 179 142 167 142 160 130 150 126 148 142 132 158 132 173 152 167 156 164 167 174 176 161 193 135 192
Rectangle -1 true false 134 199 184 205

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house bungalow
false
0
Rectangle -7500403 true true 210 75 225 255
Rectangle -7500403 true true 90 135 210 255
Rectangle -16777216 true false 165 195 195 255
Line -16777216 false 210 135 210 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 150 75 150 150 75
Line -16777216 false 75 150 225 150
Line -16777216 false 195 120 225 150
Polygon -16777216 false false 165 195 150 195 180 165 210 195
Rectangle -16777216 true false 135 105 165 135

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

house-2
false
0
Rectangle -7500403 true true 15 195 285 285
Rectangle -16777216 true false 150 210 210 285
Polygon -7500403 true true 15 180 150 120 285 180
Rectangle -16777216 true false 30 210 45 240
Rectangle -16777216 true false 240 210 255 240
Rectangle -16777216 true false 75 210 90 240
Rectangle -16777216 true false 120 210 135 240

household indicator
false
0
Circle -7500403 true true 15 15 60

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

loan
false
0
Rectangle -7500403 true true 195 45 255 135
Line -16777216 false 240 75 210 75
Line -16777216 false 210 75 210 90
Line -16777216 false 210 90 240 90
Line -16777216 false 240 90 240 105
Line -16777216 false 240 105 210 105
Line -16777216 false 225 60 225 120

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person construction
false
0
Rectangle -7500403 true true 123 76 176 95
Polygon -1 true false 105 90 60 195 90 210 115 162 184 163 210 210 240 195 195 90
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Circle -7500403 true true 110 5 80
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -955883 true false 180 90 195 90 195 165 195 195 150 195 150 120 180 90
Polygon -955883 true false 120 90 105 90 105 165 105 195 150 195 150 120 120 90
Rectangle -16777216 true false 135 114 150 120
Rectangle -16777216 true false 135 144 150 150
Rectangle -16777216 true false 135 174 150 180
Polygon -955883 true false 105 42 111 16 128 2 149 0 178 6 190 18 192 28 220 29 216 34 201 39 167 35
Polygon -6459832 true false 54 253 54 238 219 73 227 78
Polygon -16777216 true false 15 285 15 255 30 225 45 225 75 255 75 270 45 285

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

person graduate
false
0
Circle -16777216 false false 39 183 20
Polygon -1 true false 50 203 85 213 118 227 119 207 89 204 52 185
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -8630108 true false 90 19 150 37 210 19 195 4 105 4
Polygon -8630108 true false 120 90 105 90 60 195 90 210 120 165 90 285 105 300 195 300 210 285 180 165 210 210 240 195 195 90
Polygon -1184463 true false 135 90 120 90 150 135 180 90 165 90 150 105
Line -2674135 false 195 90 150 135
Line -2674135 false 105 90 150 135
Polygon -1 true false 135 90 150 105 165 90
Circle -1 true false 104 205 20
Circle -1 true false 41 184 20
Circle -16777216 false false 106 206 18
Line -2674135 false 208 22 208 57

person lumberjack
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -2674135 true false 60 196 90 211 114 155 120 196 180 196 187 158 210 211 240 196 195 91 165 91 150 106 150 135 135 91 105 91
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -6459832 true false 174 90 181 90 180 195 165 195
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -6459832 true false 126 90 119 90 120 195 135 195
Rectangle -6459832 true false 45 180 255 195
Polygon -16777216 true false 255 165 255 195 240 225 255 240 285 240 300 225 285 195 285 165
Line -16777216 false 135 165 165 165
Line -16777216 false 135 135 165 135
Line -16777216 false 90 135 120 135
Line -16777216 false 105 120 120 120
Line -16777216 false 180 120 195 120
Line -16777216 false 180 135 210 135
Line -16777216 false 90 150 105 165
Line -16777216 false 225 165 210 180
Line -16777216 false 75 165 90 180
Line -16777216 false 210 150 195 165
Line -16777216 false 180 105 210 180
Line -16777216 false 120 105 90 180
Line -16777216 false 150 135 150 165
Polygon -2674135 true false 100 30 104 44 189 24 185 10 173 10 166 1 138 -1 111 3 109 28

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
setup-random repeat 20 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

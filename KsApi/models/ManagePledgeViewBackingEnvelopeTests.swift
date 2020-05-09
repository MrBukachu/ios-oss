@testable import KsApi
import XCTest

final class ManagePledgeViewBackingEnvelopeTests: XCTestCase {
  func testJSONParsing_WithCompleteData() {
    let dictionary: [String: Any] = [
      "project": [
        "pid": 747_474_738,
        "name": "The Keyboardio Atreus",
        "state": "LIVE",
        "backing": [
          "id": "UHJvamVjdC00NDc0NzMM=",
          "status": "pledged",
          "errorReason": "This just isn't your day.",
          "pledgedOn": 1_587_502_131,
          "amount": [
            "amount": "146.0",
            "currency": "USD",
            "symbol": "$"
          ],
          "bankAccount": [
            "bankName": "Chase",
            "id": "60922339",
            "lastFour": "1234"
          ],
          "cancelable": true,
          "creditCard": [
            "id": "60981339",
            "lastFour": "1234",
            "expirationDate": "2023-04-01",
            "paymentType": "CREDIT_CARD",
            "type": "VISA"
          ],
          "location": [
            "name": "Brooklyn, NY"
          ],
          "sequence": 5,
          "shippingAmount": [
            "amount": "17.0",
            "currency": "USD",
            "symbol": "$"
          ],
          "reward": [
            "name": "Everyday Carry",
            "backersCount": 593,
            "description": "For the typist who takes their keyboard everywhere.",
            "estimatedDeliveryOn": "2020-08-01",
            "items": [
              "nodes": [
                [
                  "id": "UmV3YXJkSXRlbS03OTczNTM=",
                  "name": "Keyboardio Atreus (Choose switches after campaign)"
                ],
                [
                  "id": "UmV3YXJkSXRlbS04NzMzMDY=",
                  "name": "Travel case"
                ]
              ]
            ],
            "amount": [
              "amount": "129.0",
              "currency": "USD",
              "symbol": "$"
            ]
          ],
          "backer": [
            "uid": "565656",
            "name": "Backer McGee"
          ]
        ]
      ]
    ]

    guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
      XCTFail("Should have data")
      return
    }

    do {
      let value = try JSONDecoder().decode(ManagePledgeViewBackingEnvelope.self, from: data)

      XCTAssertEqual(value.project.pid, 747_474_738)
      XCTAssertEqual(value.project.name, "The Keyboardio Atreus")
      XCTAssertEqual(value.project.state, .live)

      XCTAssertEqual(value.backing.id, "UHJvamVjdC00NDc0NzMM=")
      XCTAssertEqual(value.backing.status, .pledged)
      XCTAssertEqual(value.backing.sequence, 5)
      XCTAssertEqual(value.backing.errorReason, "This just isn't your day.")
      XCTAssertEqual(value.backing.pledgedOn, 1_587_502_131)
      XCTAssertEqual(value.backing.amount, Money(amount: "146.0", currency: .usd, symbol: "$"))

      XCTAssertEqual(value.backing.bankAccount?.bankName, "Chase")
      XCTAssertEqual(value.backing.bankAccount?.id, "60922339")
      XCTAssertEqual(value.backing.bankAccount?.lastFour, "1234")

      XCTAssertEqual(value.backing.cancelable, true)

      XCTAssertEqual(value.backing.creditCard?.id, "60981339")
      XCTAssertEqual(value.backing.creditCard?.lastFour, "1234")
      XCTAssertEqual(value.backing.creditCard?.expirationDate, "2023-04-01")
      XCTAssertEqual(value.backing.creditCard?.paymentType, .creditCard)
      XCTAssertEqual(value.backing.creditCard?.type, .visa)

      XCTAssertEqual(value.backing.location?.name, "Brooklyn, NY")

      XCTAssertEqual(value.backing.shippingAmount, Money(amount: "17.0", currency: .usd, symbol: "$"))

      XCTAssertEqual(value.backing.reward?.name, "Everyday Carry")
      XCTAssertEqual(value.backing.reward?.backersCount, 593)
      XCTAssertEqual(
        value.backing.reward?.description,
        "For the typist who takes their keyboard everywhere."
      )
      XCTAssertEqual(value.backing.reward?.estimatedDeliveryOn, "2020-08-01")
      XCTAssertEqual(value.backing.reward?.items?[0].id, "UmV3YXJkSXRlbS03OTczNTM=")
      XCTAssertEqual(
        value.backing.reward?.items?[0].name,
        "Keyboardio Atreus (Choose switches after campaign)"
      )
      XCTAssertEqual(value.backing.reward?.items?[1].id, "UmV3YXJkSXRlbS04NzMzMDY=")
      XCTAssertEqual(value.backing.reward?.items?[1].name, "Travel case")

      XCTAssertEqual(value.backing.reward?.amount, Money(amount: "129.0", currency: .usd, symbol: "$"))

      XCTAssertEqual(value.backing.backer.uid, 565_656)
      XCTAssertEqual(value.backing.backer.name, "Backer McGee")
    } catch {
      XCTFail((error as NSError).description)
    }
  }

  func testJSONParsing_WithPartialData() {
    let dictionary: [String: Any] = [
      "project": [
        "pid": 747_474_738,
        "name": "The Keyboardio Atreus",
        "state": "LIVE",
        "backing": [
          "id": "UHJvamVjdC00NDc0NzMM=",
          "sequence": 123,
          "status": "pledged",
          "errorReason": nil,
          "pledgedOn": 1_587_502_131,
          "amount": [
            "amount": "146.0",
            "currency": "USD",
            "symbol": "$"
          ],
          "bankAccount": nil,
          "cancelable": true,
          "creditCard": nil,
          "location": nil,
          "shippingAmount": nil,
          "reward": [
            "name": "Everyday Carry",
            "backersCount": 593,
            "description": "For the typist who takes their keyboard everywhere.",
            "estimatedDeliveryOn": nil,
            "items": nil,
            "amount": [
              "amount": "129.0",
              "currency": "USD",
              "symbol": "$"
            ]
          ],
          "backer": [
            "uid": "565656",
            "name": "Backer McGee"
          ]
        ]
      ]
    ]

    guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
      XCTFail("Should have data")
      return
    }

    do {
      let value = try JSONDecoder().decode(ManagePledgeViewBackingEnvelope.self, from: data)

      XCTAssertEqual(value.project.pid, 747_474_738)
      XCTAssertEqual(value.project.name, "The Keyboardio Atreus")
      XCTAssertEqual(value.project.state, .live)

      XCTAssertEqual(value.backing.id, "UHJvamVjdC00NDc0NzMM=")
      XCTAssertEqual(value.backing.sequence, 123)
      XCTAssertEqual(value.backing.status, .pledged)
      XCTAssertNil(value.backing.errorReason)
      XCTAssertEqual(value.backing.pledgedOn, 1_587_502_131)
      XCTAssertEqual(value.backing.amount, Money(amount: "146.0", currency: .usd, symbol: "$"))

      XCTAssertNil(value.backing.bankAccount)

      XCTAssertEqual(value.backing.cancelable, true)

      XCTAssertNil(value.backing.creditCard)

      XCTAssertNil(value.backing.location)
      XCTAssertNil(value.backing.shippingAmount)

      XCTAssertEqual(value.backing.reward?.name, "Everyday Carry")
      XCTAssertEqual(value.backing.reward?.backersCount, 593)
      XCTAssertEqual(
        value.backing.reward?.description,
        "For the typist who takes their keyboard everywhere."
      )
      XCTAssertNil(value.backing.reward?.estimatedDeliveryOn)
      XCTAssertNil(value.backing.reward?.items)

      XCTAssertEqual(value.backing.reward?.amount, Money(amount: "129.0", currency: .usd, symbol: "$"))

      XCTAssertEqual(value.backing.backer.uid, 565_656)
      XCTAssertEqual(value.backing.backer.name, "Backer McGee")
    } catch {
      XCTFail((error as NSError).description)
    }
  }

  func testJSONParsing_WithPartialData_NoReward() {
    let dictionary: [String: Any] = [
      "project": [
        "pid": 747_474_738,
        "name": "The Keyboardio Atreus",
        "state": "LIVE",
        "backing": [
          "id": "UHJvamVjdC00NDc0NzMM=",
          "sequence": 123,
          "status": "pledged",
          "errorReason": nil,
          "pledgedOn": 1_587_502_131,
          "amount": [
            "amount": "146.0",
            "currency": "USD",
            "symbol": "$"
          ],
          "bankAccount": nil,
          "cancelable": true,
          "creditCard": nil,
          "location": nil,
          "shippingAmount": nil,
          "reward": nil,
          "backer": [
            "uid": "565656",
            "name": "Backer McGee"
          ]
        ]
      ]
    ]

    guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
      XCTFail("Should have data")
      return
    }

    do {
      let value = try JSONDecoder().decode(ManagePledgeViewBackingEnvelope.self, from: data)

      XCTAssertEqual(value.project.pid, 747_474_738)
      XCTAssertEqual(value.project.name, "The Keyboardio Atreus")
      XCTAssertEqual(value.project.state, .live)

      XCTAssertEqual(value.backing.id, "UHJvamVjdC00NDc0NzMM=")
      XCTAssertEqual(value.backing.sequence, 123)
      XCTAssertEqual(value.backing.status, .pledged)
      XCTAssertNil(value.backing.errorReason)
      XCTAssertEqual(value.backing.pledgedOn, 1_587_502_131)
      XCTAssertEqual(value.backing.amount, Money(amount: "146.0", currency: .usd, symbol: "$"))

      XCTAssertNil(value.backing.bankAccount)

      XCTAssertEqual(value.backing.cancelable, true)

      XCTAssertNil(value.backing.creditCard)

      XCTAssertNil(value.backing.location)
      XCTAssertNil(value.backing.shippingAmount)

      XCTAssertNil(value.backing.reward)

      XCTAssertEqual(value.backing.backer.uid, 565_656)
      XCTAssertEqual(value.backing.backer.name, "Backer McGee")
    } catch {
      XCTFail((error as NSError).description)
    }
  }

  func testJSONParsing_WithNoBacking() {
    let dictionary: [String: Any] = [
      "project": [
        "pid": 8_373_633,
        "name": "The Keyboardio Atreus",
        "state": "LIVE",
        "backing": nil
      ]
    ]

    guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
      XCTFail("Should have data")
      return
    }

    let value = try? JSONDecoder().decode(ManagePledgeViewBackingEnvelope.self, from: data)

    XCTAssertNil(value, "Deserialization considered to have failed if no backing is present.")
  }
}

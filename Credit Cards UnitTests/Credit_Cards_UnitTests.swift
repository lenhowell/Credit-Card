//
//  Credit_Cards_UnitTests.swift
//  Credit Cards UnitTests
//
//  Created by George Bauer on 8/17/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import XCTest
@testable import Credit_Cards

class Credit_Cards_UnitTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK:- Freefuncs.swift
    func testPasteboard() {
        // This is an example of a functional test case.
        let text = "This is test #13"
        copyStringToClipBoard(textToCopy: text)
        let result = getStringFromClipBoard()
        XCTAssertEqual(text, result)
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testMakeDescKey() {
        var result = ""
        var desc = ""

        desc = "SQ *SQ *FOREFLIGHT"
        result = makeDescKey(from: desc)
        XCTAssertEqual(result, "FOREFLIGHT")

        desc = "MCDONALD'S F3625"
        result = makeDescKey(from: desc)
        XCTAssertEqual(result, "MCDONALDS")

        desc = "MCDONALD`S F3625"
        result = makeDescKey(from: desc)
        XCTAssertEqual(result, "MCDONALDS")

        desc = "MCDONALD'S  Fx3620       NORTH MYRTLE SC"
        result = makeDescKey(from: desc)
        XCTAssertEqual(result, "MCDONALDS")

        //CIT-07-2-2017 - 08-11-2019.csv
        desc = "APL*ITUNES.COM/BILL 866-712-7753 CA"
        desc = "Ref*Formulyst.com 18889218458 GBR"
        desc = "HEALTHY*BACK INSTITUTE 800-216-4908 TX"
        desc = "OFFER 04 PROMOTIONAL APR ENDED 07/01/19"
        desc = "HARRYS 888-212-6855 8882126855 NY"
        desc = "AUTOPAY 221152216034323RAUTOPAY AUTO-PMT"
        desc = "SP * BLACKBOXDEALZ 5033957597 WA"
        desc = "CLKBANK*COM_5GFZUFBM 800-390-6035 ID"
        desc = "NEST LABS 8554696378 CA"
        desc = "GOOGLE*DIGIBITES G.CO HELPPAY# CA"
        desc = "SECURITY CREDIT-LPI*LITTLE PASSPORTS"
        desc = "LPI*LITTLE PASSPORTS CONTACTLP.COM CA"
        desc = "NEOGENISHUMAN855636404 855-6364040 TX"

        //C1R-09-02-2018 - 08-10-2019.csv
        let C1R09022018 = [
            "AAA ORLANDO TOW #393",
            "ATK GOLF @ TASHUA KNOL",
            "BEACH COVE RESORT F&B",
            "BIG Y 84 STRATFORD",
            "BP#9493677CIRCLE K QPS",
            "Cap 1 ElectronicPhonePmt",
            "CARALUZZI'S GEORGETO",
            "CIRCLE B 10",
            "DENNY'S #7851",
            "EXXONMOBIL    42311712",
            "GULF OIL 92063634",
            "KFC J235016",
            "LAKE & MAIN SERV CENTE",
            "RITE AID STORE - 3744",
            "SQU*SQ *GOLD STAR COAC",
            "STOP & SHOP 0620",
            "STP&SHPFUEL0663",
            "TLF*CITY LINE FLORIST",
            "THE HOME DEPOT #6236",
            "TOOJAY'S  OCOEE",
            "TRUMBULL NAILS & SPA",
            "UNIVERSITY OF WISCONSI",
            "VERIZON WRLS D2587-01",
            "VILLAGE-INN-REST #923",

        ]
        // C1R-10-01-2017 - 09-01-2018.csv
        let C1R10012017 = [
            "BURGER KING 4NJ44",
            "HARVERST MARKET WOLF",
            "MR. GAS PLUS",
            "WOLFEBORO GARAGE IRVIN",
        ]

    }//end func

    func testMakeDescKey_C1V() {
        var result = ""
        //var desc = ""
        //C1V-09-02-2018 - 08-10-2019.csv
        let C1V = [
            "7-ELEVEN 32509":           "7 ELEVEN",
            "AMTRAK AGENC1450927069712": "AMTRAK",
            "BP#9463555STRATFORD BP":   "BP",
            "BP#9155029GENE'S AUTO":    "BP",
            "CARALUZZI'S GEORGET":      "CARALUZZIS GEORGET",
            "CONSUMERREPORTS.ORG":      "CONSUMERREPORTS.ORG",
            "CRACKER BARREL #194 N MYR": "CRACKER BARREL",
            "CVS/PHARMACY #02572":      "CVS PHARMACY",
            "HNDISCOVER ST1955":        "HNDISCOVER",
            "LOWES #02651*":            "LOWES",
            "MTA*MNR STATION TIX":      "MNR STATION TIX",
            "NINO`S PIZZA":             "NINOS PIZZA",
            "NJT NWK-INT AIR   0356":   "NJT NWK INT AIR",
            "OSTERIA ROMANA MAIN":      "OSTERIA ROMANA MAIN",
            "PILOT_00337":              "PILOT",
            "PSV* Momentum Alert":      "MOMENTUM ALERT",
            "SPRINT *WIRELESS":         "SPRINT",
            "SPRINT RETAIL #030712":    "SPRINT RETAIL",
            "UBER   TRIP":              "UBER TRIP",
            "VERIZON WRLS P2027-01":    "VERIZON WRLS",
            "VIOC AE0034":              "VIOC",
            "VZWRLSS*APOCC VISN":       "VZWRLSS",
            "VZWRLSS*IVR VN":           "VZWRLSS",
            "WAL-MART #0942":           "WAL MART",
            "WAWA 860      00008607":   "WAWA",
        ]
        /* BAD RESULTS
         "EBC SECURITY, LLC":        "EBC SECURITY LLC",
         "ROUTE 40 DINER":           "ROUTE 40 DINER",

         TRUNCATE at xxx...
         "AAA ORLANDO TOW #xxx     xxx-xxx-8542 FL"
         "ABES OF MAINE           xxx-xxx-1777 NJ"
         "ALLSTATE    *PAYMENT     xxx-xxx-7828 IL"
         "BED BATH&BEYOND #xxx   xxx-xxx-4333 NJ"
         "LONGHORN STEAKxxxx3264   WINTER GARDENFL"

         "MCDONALD'S  Fx3620       NORTH MYRTLE SC"
         
         problems
         "ALG*AIR     7BN2JZ       xxx-xxx-8888 NV" => "AIR     7BN2JZ       xxx-xxx-8888 NV"

         "BB&T PUCKETT SCHEETZ AND xxx-xxx8122  SC" => "BB&T PUCKETT SCHEETZ&xxx-xxx8122  SC"
         "APPLEBEES NEIxxxx6818   BOYNTON BEACHFL"
         "BP#xxx5702CIRCLE K ST 27 NORTH MYRTLE SC"
         "IHOP #xx-092             GAINESVILLE  FL"
         "JETBLUE     2xxxxxxxx0098SALT LAKE CTYUT"
         "MARATHON PETROxx0003"
         "MICROSOFT   *OFFICE xxx  xxx-xxx-7676 WA"
         "PAYPAL *FANKEKE          xxx-xxx-7733 CA"
         "PAYPAL *LAKEAMPHIBI      xxx-xxx-7733 CA"
         "PP*WHIRLWIND SUN N FUN   CLEARWATER   FL"
         "RACETRAC465   xxxx4655   CLERMONT     FL"
         "SUNPASS*ACCxx7622        xxx-xxx-5352 FL"

         "SWA*EARLYBRDxxxxxxxxxxxxxxxx-xxx-9792 TX"

         "UBER TECHNOLOGIES INC    xxx-xxx-1039 CA"
         "VERIZON WRLS Pxxx7-01    WINTER GARDENFL"   -> [VERIZON WRLS P]
         "WAWA xxxx     xxxx2241   SARASOTA     FL"
         "WHATCHA MCCOLLUM CAR RENTxxx-xxx5816  SC"
         "Wikimediaxxxxxx9454      xxx-xxx9454  CA"
         */

        //C1V-10-01-2017 - 09-01-2018.csv
        let xxxx = [
            "ABC FINE WINE/SPIRITS 156",
            "APPLEBEE'S NEI98696818",
            "DROPBOX*7YNSFZ4JM6FQ",
            "E & J PACKAGE STORE",
            "EBC SECURITY, LLC",
            "HARVERST MARKET WOL",
            "INTEREST CHARGE:PURCHASES",
            "INDEPENDENT IMAGING,",
            "KFC J235017",
            "MARATHON PETRO149260",
            "MOTEL 6 YOUNGSTOWN #4553",
            "NH LIQUOR STORE #66",
            "NINETY 9 BOTTLES TRUMBULL",
            "OPC TAX*SERVICE FEE 024",
            "PALM BEACH TAN CNT003",
            "PARKER STEAKS & SCOTCH",
            "STARLANDER BECK, INC",
            "SUPER 8",
            "TINAS NAIL AND SKIN",
            "TRUMBULL NAILS & SPA",
            "TACO BELL# 29310",
            "UBER   US OCT30 JAHQC",
            "WM SUPERCENTER #942",
            "YULEE 10",
            "ZIPS #9",
        ]


        for (key, value) in C1V {
            result = makeDescKey(from: key)
            XCTAssertEqual(result, String(value.prefix(descKeyLength)))
        }


    }



    // DIS-05/16/2018 - 05-16-2019.csv
    let DIS1819 = [
        "BEST BUY MH00006882295 PALM BEACH GAFL",
        "BONEFISH 7027 BOYNTON BEACHFL00422R",
        "HARVEST MARKET WOLFBORO WOLFBORO FALLNH",
        "HUNTER'S SHOP 'N SAVE WOLFEBORO NHCASHOVER $ 40.00 PURCHASES $ 106.07",
        "KROGER #770 OWENSBORO KY",
        "MEINEKE CAR CARE CENTER MONROE CT",
        "MORRISSEYS FRONT PORCH WOLFEBORO NH",
        "OLD TOWNE RESTAURANT TRUMBULL CT",
        "STOP & SHOP 0620 TRUMBULL CT01775R",
        "STP&SHPFUEL0639 STRATFORD CT03061R",
        "TRADER JOE'S #524 QPS ORANGE CT",
        "VAZZYS OSTERIA MONROE CT",
    ]

    /* Same at 1st 8 chars
     "APPLEBEES"            "APPLEBEES NEI"      ok to 9
     "AMAZON COM"           "AMAZON COM AMZ"     ok to 10
     "GOLDEN CORRAL 08"     "GOLDEN CORRAL 26"   ok to 14
     "BOSTON MARKET 01"     "BOSTON MARKET 09"   ok to 14
     "INTEREST CHARGE"     "INTEREST CHARGED"    ok to 15
     "MCDONALDS F3625"      "MCDONALDS F4902"    ok to 10
     "MCDONALDS F7973"      "MCDONALDS FX2025"   ok to 10
     "PROMO PRICING CR"     "PROMO PRICING DE"   ok to 14
     "RACETRAC465"          "RACETRAC599"        ok to 8
     "SPEEDWAY X6462"       "SPEEDWAY X6757"     ok to 9

     "COUNTRY CORNER C"     "COUNTRY HOUSE RE"   needs 9 or 10
     "ORLANDO APOPKA A"     "ORLANDO CLEANERS"   needs 9 or 10
     "VERIZON WRL MY A"     "VERIZON WRLS P"


     APL*APPLE ONLINE STORE
     APL*ITUNES.COM/BILL
     EMS*TACGLASSES
     BB *SAVE THE CHILDREN
     BB *SHRINERS HOSPITALS
     GLT*GOLF TAILOR
     IPM*INVESTORPLACE MED
     MTA*MNR STATION TIX
     OPC*CONNECTICUT DEPT REV
     PSV* Momentum Alert
     PAY*THE BARNARD HOUSE BED
     PHR*CONNECTICUTORTHOP
     PHR*ConnecticutOrthopaedi
     Ref*Formulyst.com
     SP * BLACKBOXDEALZ
     SR *Stansberry Research
     TLF*CITY LINE FLORIST
     TST* WINDMILL TAVERN

     CLKBANK*ORGANIFI (7)
     CLKBANK*COM_5GFZUFBM (7)
     DROPBOX*6J696N7MMMSW (7)
     HEALTHY*BACK INSTITUTE (7)
     LIFELOC*STANDARD (7)
     OPC TAX*SERVICE FEE (7)
     PAYPAL *TAJSBLUES02 (7)
     PAYPAL *DLM1130 (7)
     SPRINT *WIRELESS (7)

     REVERSE EMS*TACGLASSES(11)
     REVERSE PAYPAL *DLM1130(15)
     SECURITY CREDIT-EMS*TACGLASSES(19)
     SECURITY CREDIT-PAYPAL *DLM1130 (23)

     APPLE STORE  #R102
     FOOD BAZAAR #36
     NH LIQUOR STORE #66
     TACO BELL#
     ZIPS #9

     */

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}

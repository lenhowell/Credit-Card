//
//  MakeDescKeyTests.swift
//  Credit Cards UnitTests
//
//  Created by George Bauer on 8/19/19.
//  Copyright © 2019 George Bauer. All rights reserved.
//

import XCTest
@testable import Credit_Cards

class MakeDescKeyTests: XCTestCase {
    var dictVendorShortNames = [String: String]()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Glob.isUnitTesting = true
        Glob.userInputMode = false
        Glob.learnMode = false
        allowAlerts = false
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        Glob.isUnitTesting = false
        allowAlerts = true
    }

    func testNumberEdgeCases() {
        var result = ""
        var desc = ""

        desc = "STEAK-N-SHAKE#0382 Q99"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "STEAK N SHAKE")

        desc = "SWEET TOMATOES 72 Q14    ORLANDO      FL"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "SWEET TOMATOES")

        desc = "ROUTE 40 DINER"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "ROUTE 40 DINER")

        desc = "FISH AT 30 LAKE"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "FISH AT 30 LAKE")

        desc = "SUPER 8"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "SUPER 8")

        desc = "CIRCLE B 10"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "CIRCLE B")

        desc = "LANCASTER CANCxxxx5164   LANCASTER    PA"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "LANCASTER CANC")
}

    func testProblems() {
        var result = ""
        var desc = ""



        dictVendorShortNames = [ "STP&SHPFUEL": "STP&SHPFUEL" ]

        desc = "STP&SHPFUEL0639 STRATFORD CT03061R"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "STP&SHPFUEL")

        dictVendorShortNames = [String: String]()


        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "STP&SHPFUEL0639 STRATFOR")

        desc = "BIG Y 84 STRATFORD"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "BIG Y 84 STRATFORD")

        desc = "The Adventure Park at Dis"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "ADVENTURE PARK AT DIS")

    }

    func testPrefix()  {

        var result = ""
        var desc = ""

        desc = "HUM*HUMANN8556364040 855-6364040 TX"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "HUM HUMANN")

        // Without Glob.dictVendorShortNames
        desc = "VZWRLSS*APOCC VISN"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "VZWRLSS APOCC VISN")

        desc = "VZWRLSS*IVR VN"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "VZWRLSS IVR VN")

        desc = "VERIZON WRLS P2027-01"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        //XCTAssertEqual(result, "VERIZON WRLS")


        dictVendorShortNames = [ "VERIZON W": "VERIZON WIRELESS", "VZWRLSS": "VERIZON WIRELESS" ]

        // With Glob.dictVendorShortNames
        desc = "VZWRLSS*APOCC VISN"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "VERIZON WIRELESS")

        desc = "VZWRLSS*IVR VN"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "VERIZON WIRELESS")

        desc = "VERIZON WRLS P2027-01"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "VERIZON WIRELESS")

        dictVendorShortNames = [String: String]()


        desc = "APL*ITUNES.COM/BILL 866-712-7753 CA"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "ITUNES.COM BILL")

        desc = "SP * BLACKBOXDEALZ 5033957597 WA"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "BLACKBOXDEALZ")

        desc = "CLKBANK*COM_5GFZUFBM 800-390-6035 ID"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "CLKBANK COM 5GFZUFBM")

        desc = "SQ *SQ *FOREFLIGHT"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "FOREFLIGHT")

        desc = "Ref*Formulyst.com 18889218458 GBR"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "FORMULYST.COM")

        desc = "PP*WHIRLWIND SUN N FUN   CLEARWATER   FL"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "PP WHIRLWIND SUN N FUN")

        desc = "GOOGLE*DIGIBITES G.CO HELPPAY# CA"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "GOOGLE DIGIBITES G.CO HE")

        desc = "MTA*MNR STATION TIX"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "MNR STATION TIX")

        desc = "PSV* Momentum Alert"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "MOMENTUM ALERT")

        desc = "SWA*EARLYBRDxxxxxxxxxxxxxxxx-xxx-9792 TX"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "SWA EARLYBRD")

        desc = "ALG*AIR     7BN2JZ       xxx-xxx-8888 NV"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "ALG AIR")

        desc = "SQ *RETHREADS"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "RETHREADS")

        desc = "PAYPAL *TYOMA            xxx-xxx-7733 CA"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "PAYPAL TYOMA")

        desc = "PAYPAL *FANKEKE          xxx-xxx-7733 CA"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "PAYPAL FANKEKE")

        desc = "PAYPAL *MACNANBIO      xxx-xxx-7733 CA"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "MACNANBIO PAYPAL")

        desc = "PAYPAL *LAKEAMPHIBI      xxx-xxx-7733 CA"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "LAKEAMPHIBI PAYPAL")

 }

    func testMakeDescKey() {
        var result = ""
        var desc = ""

        desc = "APPLEBEE'S NEI98696818"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "APPLEBEES")

        desc = "ATK GOLF @ TASHUA KNOL"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "ATK GOLF TASHUA KNOL")

        desc = "AUTOPAY 221152216034323RAUTOPAY AUTO-PMT"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "AUTOPAY")

        desc = "BURGER KING 4NJ44"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "BURGER KING")

        desc = "KFC J235016"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "KFC")

        desc = "MCDONALD'S F3625"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "MCDONALDS")

        desc = "MCDONALD'S  Fx3620       NORTH MYRTLE SC"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "MCDONALDS")

        desc = "STOP & SHOP 0620"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "STOP&SHOP")

        desc = "STP&SHPFUEL0663"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "STP&SHPFUEL")


        // ************** PROBLEMS!! ****************
        desc = "HEALTHY*BACK INSTITUTE 800-216-4908 TX"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "HEALTHY BACK INSTITUTE")

        desc = "OFFER 04 PROMOTIONAL APR ENDED 07/01/19"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "OFFER PROMOTIONAL APR EN")

        desc = "UBER   TRIP"
        result = DescriptionKey.makeDescKey(from: desc, dictVendorShortNames: dictVendorShortNames)
        XCTAssertEqual(result, "UBER")


        //CIT-07-2-2017 - 08-11-2019.csv
        desc = "SECURITY CREDIT-LPI*LITTLE PASSPORTS"
        desc = "LPI*LITTLE PASSPORTS CONTACTLP.COM CA"



        //C1R-09-02-2018 - 08-10-2019.csv
        _ = [
            "Cap 1 ElectronicPhonePmt",
            "CIRCLE B 10",
            "RITE AID STORE - 3744",
            "TLF*CITY LINE FLORIST",
            "VERIZON WRLS D2587-01",
        ]

    }//end func

    func testMakeDescKey_C1V() {
        var result = ""
        //var desc = ""
        //C1V-09-02-2018 - 08-10-2019.csv
        let C1V = [
            "7-ELEVEN 32509":            "7 ELEVEN",
            "ABC FINE WINE/SPIRITS 156": "ABC FINE WINE SPIRITS",
            "AMTRAK AGENC1450927069712": "AMTRAK",
            "BP#9463555STRATFORD BP":    "BP",
            "BP#9155029GENE'S AUTO":     "BP",
            "BP#9493677CIRCLE K QPS":    "BP",
            "CARALUZZI'S GEORGET":       "CARALUZZIS GEORGET",
            "CONSUMERREPORTS.ORG":       "CONSUMERREPORTS.ORG",
            "CRACKER BARREL #194 N MYR": "CRACKER BARREL",
            "CVS/PHARMACY #02572":       "CVS PHARMACY",
            "SQU*SQ *GOLD STAR COAC":    "GOLD STAR COAC",
            "HARVERST MARKET WOLF":      "HARVERST MARKET WOLF",
            "HNDISCOVER ST1955":         "HNDISCOVER",
            "LAKE & MAIN SERV CENTE":    "LAKE&MAIN SERV CENTE",
            "LOWES #02651*":             "LOWES",
            "MR. GAS PLUS":              "MR. GAS PLUS",
            "NH LIQUOR STORE #66":       "NH LIQUOR STORE",
            "NINO`S PIZZA":              "NINOS PIZZA",
            "NJT NWK-INT AIR   0356":    "NJT NWK INT AIR",
            "OSTERIA ROMANA MAIN":       "OSTERIA ROMANA MAIN",
            "PILOT_00337":               "PILOT",
            "SPRINT *WIRELESS":          "SPRINT WIRELESS",
            "SPRINT RETAIL #030712":     "SPRINT RETAIL",
            "VILLAGE-INN-REST #923":     "VILLAGE INN REST",
            "VIOC AE0034":               "VIOC",
            "WAWA 860      00008607":    "WAWA",

            "APPLEBEES NEIxxxx6818   BOYNTON BEACHFL":  "APPLEBEES",
            "BB&T PUCKETT SCHEETZ AND xxx-xxx8122  SC": "BB&T PUCKETT SCHEETZ&",
            "HARRYS 888-212-6855 8882126855 NY":        "HARRYS",
            "IHOP #xx-092             GAINESVILLE  FL": "IHOP",
            "LONGHORN STEAKxxxx3264   WINTER GARDENFL": "LONGHORN STEAK",
            "MCDONALD'S  Fx3620       NORTH MYRTLE SC": "MCDONALDS",
            "NEOGENISHUMAN855636404 855-6364040 TX":    "NEOGENISHUMAN",
            "RACETRAC465   xxxx4655   CLERMONT     FL": "RACETRAC",

            ]

        /* BAD RESULTS
         "EBC SECURITY, LLC":        "EBC SECURITY LLC",
         "ROUTE 40 DINER":           "ROUTE 40 DINER",

         TRUNCATE at xxx...
         "AAA ORLANDO TOW #xxx     xxx-xxx-8542 FL"
         "ABES OF MAINE           xxx-xxx-1777 NJ"
         "ALLSTATE    *PAYMENT     xxx-xxx-7828 IL"
         "BED BATH&BEYOND #xxx   xxx-xxx-4333 NJ"

         problems
         "ALG*AIR     7BN2JZ       xxx-xxx-8888 NV" => "AIR     7BN2JZ       xxx-xxx-8888 NV"

         "BP#xxx5702CIRCLE K ST 27 NORTH MYRTLE SC"
         "JETBLUE     2xxxxxxxx0098SALT LAKE CTYUT"
         "MARATHON PETROxx0003"
         "MICROSOFT   *OFFICE xxx  xxx-xxx-7676 WA"
         "PAYPAL *FANKEKE          xxx-xxx-7733 CA"
         "PAYPAL *LAKEAMPHIBI      xxx-xxx-7733 CA"
         "PP*WHIRLWIND SUN N FUN   CLEARWATER   FL"
         "SUNPASS*ACCxx7622        xxx-xxx-5352 FL"

         "SWA*EARLYBRDxxxxxxxxxxxxxxxx-xxx-9792 TX"

         "VERIZON WRLS Pxxx7-01    WINTER GARDENFL"   -> [VERIZON WRLS P]
         "WAWA xxxx     xxxx2241   SARASOTA     FL"
         "WHATCHA MCCOLLUM CAR RENTxxx-xxx5816  SC"
         "Wikimediaxxxxxx9454      xxx-xxx9454  CA"
         */

        //C1V-10-01-2017 - 09-01-2018.csv
        _ = [
            "DROPBOX*7YNSFZ4JM6FQ",
            "E & J PACKAGE STORE",
            "EBC SECURITY, LLC",
            "HARVERST MARKET WOL",
            "INTEREST CHARGE:PURCHASES",
            "INDEPENDENT IMAGING,",
            "KFC J235017",
            "MARATHON PETRO149260",
            "MOTEL 6 YOUNGSTOWN #4553",
            "NINETY 9 BOTTLES TRUMBULL",
            "OPC TAX*SERVICE FEE 024",
            "PALM BEACH TAN CNT003",
            "PARKER STEAKS & SCOTCH",
            "STARLANDER BECK, INC",
            "TRUMBULL NAILS & SPA",
            "TACO BELL# 29310",
            "UBER   US OCT30 JAHQC",
            "WM SUPERCENTER #942",
            "YULEE 10",
            "ZIPS #9",
        ]

        dictVendorShortNames = [ "APPLEBEES": "APPLEBEES" ]

        for (key, value) in C1V {
            result = DescriptionKey.makeDescKey(from: key, dictVendorShortNames: dictVendorShortNames)
            XCTAssertEqual(result, String(value.prefix(Const.descKeyLength)))
        }


    }



    // DIS-05/16/2018 - 05-16-2019.csv
    let DIS1819 = [
        //23456789012345678
        "BEST BUY MH00006882295 PALM BEACH GAFL",
        "BONEFISH 7027 BOYNTON BEACHFL00422R",
        "HARVEST MARKET WOLFBORO WOLFBORO FALLNH",
        "HUNTER'S SHOP 'N SAVE WOLFEBORO NHCASHOVER $ 40.00 PURCHASES $ 106.07",
        "KROGER #770 OWENSBORO KY",
        "MEINEKE CAR CARE CENTER MONROE CT",
        "MORRISSEYS FRONT PORCH WOLFEBORO NH",
        "OLD TOWNE RESTAURANT TRUMBULL CT",
        "STOP & SHOP 0620 TRUMBULL CT01775R",
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

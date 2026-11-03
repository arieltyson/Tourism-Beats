#!/usr/bin/env python3
"""Builds the bundled airport directory used by Flight Countdown.

Sources
- OurAirports (public domain): https://ourairports.com/data/
  Airports with scheduled passenger service and an IATA code.
- mwgg/Airports (MIT): https://github.com/mwgg/Airports
  IANA time zone identifiers, so a departure airport sets its own time zone.

Usage
    python3 Scripts/generate_airports.py "Tourism Beats/Resources/airports.json"

The output is compact JSON, sorted by code, so regenerating produces
reviewable diffs.
"""

import csv
import io
import json
import math
import re
import sys
import urllib.request

OURAIRPORTS_URL = "https://davidmegginson.github.io/ourairports-data/airports.csv"
MWGG_URL = "https://raw.githubusercontent.com/mwgg/Airports/master/airports.json"

AIRPORT_TYPES = {"large_airport": 0, "medium_airport": 1, "small_airport": 2}

# Airports people think of as serving one city, even when they sit outside it.
# Searching for the city lists every one of them together.
METROPOLITAN_AREAS = {
    "London": ["LHR", "LGW", "STN", "LTN", "LCY", "SEN"],
    "New York": ["JFK", "LGA", "EWR"],
    "Washington": ["DCA", "IAD", "BWI"],
    "Chicago": ["ORD", "MDW"],
    "Dallas": ["DFW", "DAL"],
    "Houston": ["IAH", "HOU"],
    "Miami": ["MIA", "FLL"],
    "Los Angeles": ["LAX", "BUR", "LGB", "SNA", "ONT"],
    "San Francisco": ["SFO", "OAK", "SJC"],
    "Seattle": ["SEA", "PAE"],
    "Orlando": ["MCO", "SFB"],
    "Toronto": ["YYZ", "YTZ"],
    "Montréal": ["YUL"],
    "Mexico City": ["MEX", "NLU"],
    "São Paulo": ["GRU", "CGH", "VCP"],
    "Rio de Janeiro": ["GIG", "SDU"],
    "Buenos Aires": ["EZE", "AEP"],
    "Paris": ["CDG", "ORY", "BVA"],
    "Milan": ["MXP", "LIN", "BGY"],
    "Rome": ["FCO", "CIA"],
    "Venice": ["VCE", "TSF"],
    "Brussels": ["BRU", "CRL"],
    "Stockholm": ["ARN", "BMA", "NYO"],
    "Oslo": ["OSL", "TRF"],
    "Glasgow": ["GLA", "PIK"],
    "Belfast": ["BFS", "BHD"],
    "Reykjavík": ["KEF", "RKV"],
    "Tenerife": ["TFS", "TFN"],
    "Bucharest": ["OTP", "BBU"],
    "Moscow": ["SVO", "DME", "VKO"],
    "Istanbul": ["IST", "SAW"],
    "Dubai": ["DXB", "DWC"],
    "Tokyo": ["HND", "NRT"],
    "Osaka": ["KIX", "ITM"],
    "Seoul": ["ICN", "GMP"],
    "Shanghai": ["PVG", "SHA"],
    "Beijing": ["PEK", "PKX"],
    "Taipei": ["TPE", "TSA"],
    "Bangkok": ["BKK", "DMK"],
    "Kuala Lumpur": ["KUL", "SZB"],
    "Jakarta": ["CGK", "HLP"],
}

# Nearest-neighbour fallback for small airports without a time zone,
# limited so an island airport never borrows a far-away mainland zone.
MAXIMUM_TIME_ZONE_DISTANCE_KM = 150
MAXIMUM_ALIASES_LENGTH = 120


def fetch(url):
    with urllib.request.urlopen(url) as response:
        return response.read().decode("utf-8")


def distance_km(a, b):
    lat1, lon1, lat2, lon2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    h = math.sin((lat2 - lat1) / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2
    return 6371 * 2 * math.asin(math.sqrt(h))


def clean_city(municipality):
    """'Paris (Roissy-en-France, Val-d'Oise)' -> 'Paris', 'London, Essex' -> 'London'."""
    city = re.sub(r"\s*\(.*?\)", "", municipality)
    return city.split(",")[0].strip()


def main(output_path):
    zones = json.loads(fetch(MWGG_URL))
    zone_by_icao = {key: value["tz"] for key, value in zones.items() if value.get("tz")}
    zone_by_iata = {value["iata"]: value["tz"] for value in zones.values() if value.get("iata") and value.get("tz")}
    located_zones = [((value["lat"], value["lon"]), value["tz"]) for value in zones.values() if value.get("tz")]

    metro_by_code = {code: metro for metro, codes in METROPOLITAN_AREAS.items() for code in codes}
    airports = []
    for row in csv.DictReader(io.StringIO(fetch(OURAIRPORTS_URL))):
        code = row["iata_code"]
        if row["scheduled_service"] != "yes" or row["type"] not in AIRPORT_TYPES:
            continue
        if not re.fullmatch(r"[A-Z]{3}", code):
            continue
        zone = zone_by_icao.get(row["icao_code"] or row["ident"]) or zone_by_iata.get(code)
        if zone is None:
            location = (float(row["latitude_deg"]), float(row["longitude_deg"]))
            nearest = min(located_zones, key=lambda item: distance_km(location, item[0]))
            if distance_km(location, nearest[0]) <= MAXIMUM_TIME_ZONE_DISTANCE_KM:
                zone = nearest[1]
        if zone is None:
            continue
        city = clean_city(row["municipality"]) or row["name"]
        airport = {
            "code": code,
            "name": row["name"],
            "city": city,
            "country": row["iso_country"],
            "timeZone": zone,
            "size": AIRPORT_TYPES[row["type"]],
        }
        metro = metro_by_code.get(code)
        if metro and metro != city:
            airport["metro"] = metro
        aliases = ", ".join(
            part.strip() for part in row["keywords"].split(",") if part.strip() and part.strip() != code
        )
        if aliases:
            airport["aliases"] = aliases[:MAXIMUM_ALIASES_LENGTH]
        airports.append(airport)

    codes = {airport["code"] for airport in airports}
    missing = sorted(code for code in metro_by_code if code not in codes)
    if missing:
        print(f"warning: metropolitan codes without scheduled service: {missing}", file=sys.stderr)

    # Duplicated IATA codes keep the airport with the most service.
    unique = {}
    for airport in sorted(airports, key=lambda item: item["size"]):
        unique.setdefault(airport["code"], airport)
    result = sorted(unique.values(), key=lambda item: item["code"])
    with open(output_path, "w", encoding="utf-8") as file:
        json.dump(result, file, ensure_ascii=False, separators=(",", ":"))
    print(f"wrote {len(result)} airports to {output_path}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "airports.json")

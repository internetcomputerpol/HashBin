
// WYMAGA pakietu mops "sha2" (https://mops.one/sha2)
//   [dependencies]
//   core = "0.7.0"   # lub najnowsza wersja z https://mops.one/core
//   sha2 = "0.1.12"  # lub najnowsza wersja z https://mops.one/sha2

import Map "mo:core/Map";
import Text "mo:core/Text";
import Nat "mo:core/Nat";
import Nat8 "mo:core/Nat8";
import Int "mo:core/Int";
import Iter "mo:core/Iter";
import Time "mo:core/Time";
import Sha256 "mo:sha2/Sha256";

persistent actor HashRegistry {


  public type Entry = {
    id : Nat;         
    timestamp : Text;  // "HH:MM:SS_DD-MM-RRRR"
    hashHex : Text;     // SHA-256 z połączonych 4 wartości Text (hex)
    value1 : Text;
    value2 : Text;
    value3 : Text;
    value4 : Text;
  };

  let entriesById = Map.empty<Nat, Entry>();

  let idByHash = Map.empty<Text, Nat>();

// Główny licznik dla obiektów w Map
  var nextId : Nat = 0;


//Text -> hex Text (SHA-256)
// Łączymy 4 wartości w jeden Blob (z separatorem, by uniknąć kolizji typu
// ("ab","c") vs ("a","bc")) i liczymy SHA-256.
  func computeHash(v1 : Text, v2 : Text, v3 : Text, v4 : Text) : Blob {
    let combined : Text = v1 # "\u{1F}" # v2 # "\u{1F}" # v3 # "\u{1F}" # v4;
    let bytes : Blob = Text.encodeUtf8(combined);
    Sha256.fromBlob(#sha256, bytes);
  };

  let hexChars : [Char] = [
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'
  ];

  // Konwersja Blob -> Text w formacie hex (np. "a1b2c3...").
  func blobToHex(b : Blob) : Text {
    var result = "";
    for (byte in b.vals()) {
      let n = Nat8.toNat(byte);
      let hi = n / 16;
      let lo = n % 16;
      result #= Text.fromChar(hexChars[hi]);
      result #= Text.fromChar(hexChars[lo]);
    };
    result;
  };


  func formatTimestamp(nanos : Int) : Text {
    let totalSeconds : Int = nanos / 1_000_000_000;
    let secondsOfDay : Int = ((totalSeconds % 86_400) + 86_400) % 86_400;
    let daysSinceEpoch : Int = (totalSeconds - secondsOfDay) / 86_400;

    let hour = secondsOfDay / 3600;
    let minute = (secondsOfDay % 3600) / 60;
    let second = secondsOfDay % 60;

    let (year, month, day) = civilFromDays(daysSinceEpoch);

    pad2(Int.abs(hour)) # ":" # pad2(Int.abs(minute)) # ":" # pad2(Int.abs(second))
      # "_" # pad2(Int.abs(day)) # "-" # pad2(Int.abs(month)) # "-" # Int.toText(year);
  };

  // Dopełnienie liczby do 2 cyfr, np. 5 -> "05".
  func pad2(n : Nat) : Text {
    if (n < 10) { "0" # Nat.toText(n) } else { Nat.toText(n) };
  };


  func civilFromDays(z0 : Int) : (Int, Int, Int) {
    let z = z0 + 719_468;
    let era = (if (z >= 0) z else z - 146_096) / 146_097;
    let doe = (z - era * 146_097); // [0, 146096]
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365; // [0, 399]
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100); // [0, 365]
    let mp = (5 * doy + 2) / 153; // [0, 11]
    let d = doy - (153 * mp + 2) / 5 + 1; // [1, 31]
    let m = if (mp < 10) (mp + 3) else (mp - 9); // [1, 12]
    let year = if (m <= 2) (y + 1) else y;
    (year, m, d);
  };


  public func addEntry(v1 : Text, v2 : Text, v3 : Text, v4 : Text) : async Entry {
    let hashBlob = computeHash(v1, v2, v3, v4);
    let hashHex = blobToHex(hashBlob);

    let id = nextId;
    nextId += 1;

    let entry : Entry = {
      id;
      timestamp = formatTimestamp(Time.now());
      hashHex;
      value1 = v1;
      value2 = v2;
      value3 = v3;
      value4 = v4;
    };

    Map.add(entriesById, Nat.compare, id, entry);
    Map.add(idByHash, Text.compare, hashHex, id);

    entry;
  };

  public query func getById(id : Nat) : async ?Entry {
    Map.get(entriesById, Nat.compare, id);
  };

  public query func getByHash(hashHex : Text) : async ?Entry {
    switch (Map.get(idByHash, Text.compare, hashHex)) {
      case null { null };
      case (?id) { Map.get(entriesById, Nat.compare, id) };
    };
  };


  public query func getAll() : async [Entry] {
    Iter.toArray(Iter.map(Map.entries(entriesById), func((_, entry) : (Nat, Entry)) : Entry { entry }));
  };

  public query func count() : async Nat {
    Map.size(entriesById);
  };
};

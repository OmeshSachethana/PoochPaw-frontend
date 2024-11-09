import 'dart:convert';

final Map<String, dynamic> dogHealthData = jsonDecode(jsonEncode({
  "breeds": {
    "German Shepherd": {
      "age": {
        "0-2": {
          "weightRange": {
            "normal": "10-30 kg",
            "unhealthy": {"underweight": "<9 kg", "overweight": ">30 kg"}
          }
        },
        "3-7": {
          "weightRange": {
            "normal": "22-40 kg",
            "unhealthy": {"underweight": "<22 kg", "overweight": ">40 kg"}
          }
        },
        "8+": {
          "weightRange": {
            "normal": "20-32 kg",
            "unhealthy": {"underweight": "<20 kg", "overweight": ">32 kg"}
          }
        }
      }
    },
    "Boxer": {
      "age": {
        "0-2": {
          "weightRange": {
            "normal": "10-25 kg",
            "unhealthy": {"underweight": "<10 kg", "overweight": ">25 kg"}
          }
        },
        "3-7": {
          "weightRange": {
            "normal": "25-32 kg",
            "unhealthy": {"underweight": "<25 kg", "overweight": ">32 kg"}
          }
        },
        "8+": {
          "weightRange": {
            "normal": "22-30 kg",
            "unhealthy": {"underweight": "<22 kg", "overweight": ">30 kg"}
          }
        }
      }
    },
    "Rottweiler": {
      "age": {
        "0-2": {
          "weightRange": {
            "normal": "20-35 kg",
            "unhealthy": {"underweight": "<20 kg", "overweight": ">35 kg"}
          }
        },
        "3-7": {
          "weightRange": {
            "normal": "35-50 kg",
            "unhealthy": {"underweight": "<35 kg", "overweight": ">50 kg"}
          }
        },
        "8+": {
          "weightRange": {
            "normal": "32-45 kg",
            "unhealthy": {"underweight": "<32 kg", "overweight": ">45 kg"}
          }
        }
      }
    },
    "Doberman": {
      "age": {
        "0-2": {
          "weightRange": {
            "normal": "12-28 kg",
            "unhealthy": {"underweight": "<12 kg", "overweight": ">28 kg"}
          }
        },
        "3-7": {
          "weightRange": {
            "normal": "28-40 kg",
            "unhealthy": {"underweight": "<28 kg", "overweight": ">40 kg"}
          }
        },
        "8+": {
          "weightRange": {
            "normal": "25-36 kg",
            "unhealthy": {"underweight": "<25 kg", "overweight": ">36 kg"}
          }
        }
      }
    },
    "Pitbull Terrier": {
      "age": {
        "0-2": {
          "weightRange": {
            "normal": "10-20 kg",
            "unhealthy": {"underweight": "<10 kg", "overweight": ">20 kg"}
          }
        },
        "3-7": {
          "weightRange": {
            "normal": "20-30 kg",
            "unhealthy": {"underweight": "<20 kg", "overweight": ">30 kg"}
          }
        },
        "8+": {
          "weightRange": {
            "normal": "18-28 kg",
            "unhealthy": {"underweight": "<18 kg", "overweight": ">28 kg"}
          }
        }
      }
    }
  }
}));

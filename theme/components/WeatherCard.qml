import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    property color primary: "#fbba73"
    property color surfaceContainer: "#251e17"
    property color onSurface: "#eee0d5"
    property color onSurfaceVariant: "#d5c4b5"
    property string fontFamily: "sans-serif"

    property string condition: "Loading weather…"
    property real tempC: NaN
    property real feelsLikeC: NaN
    property real highC: NaN
    property real lowC: NaN
    property int currentCode: 0
    property var hourly: []

    readonly property var weatherIcons: ({
        "0": "clear_day",
        "1": "clear_day",
        "2": "partly_cloudy_day",
        "3": "cloud",
        "45": "foggy",
        "48": "foggy",
        "51": "rainy",
        "53": "rainy",
        "55": "rainy",
        "56": "rainy",
        "57": "rainy",
        "61": "rainy",
        "63": "rainy",
        "65": "rainy",
        "66": "rainy",
        "67": "rainy",
        "71": "cloudy_snowing",
        "73": "cloudy_snowing",
        "75": "snowing_heavy",
        "77": "cloudy_snowing",
        "80": "rainy",
        "81": "rainy",
        "82": "rainy",
        "85": "cloudy_snowing",
        "86": "snowing_heavy",
        "95": "thunderstorm",
        "96": "thunderstorm",
        "99": "thunderstorm"
    })

    readonly property var conditionText: ({
        "0": "Clear sky",
        "1": "Mostly clear",
        "2": "Partly cloudy",
        "3": "Overcast",
        "45": "Fog",
        "48": "Fog",
        "51": "Light drizzle",
        "53": "Drizzle",
        "55": "Heavy drizzle",
        "56": "Freezing drizzle",
        "57": "Freezing drizzle",
        "61": "Light rain",
        "63": "Rain",
        "65": "Heavy rain",
        "66": "Freezing rain",
        "67": "Freezing rain",
        "71": "Light snow",
        "73": "Snow",
        "75": "Heavy snow",
        "77": "Snow grains",
        "80": "Light showers",
        "81": "Showers",
        "82": "Heavy showers",
        "85": "Snow showers",
        "86": "Heavy snow showers",
        "95": "Thunderstorm",
        "96": "Thunderstorm with hail",
        "99": "Thunderstorm with hail"
    })

    function iconFor(code) {
        return weatherIcons[String(code)] || "air";
    }

    function textFor(code) {
        return conditionText[String(code)] || "Unknown";
    }

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    function fetchWeather(lat, lon) {
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,apparent_temperature,weather_code&hourly=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1";
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE)
                return;
            if (x.status !== 200) {
                root.condition = "Weather unavailable";
                return;
            }
            try {
                var json = JSON.parse(x.responseText);
                root.tempC = json.current.temperature_2m;
                root.feelsLikeC = json.current.apparent_temperature;
                root.currentCode = json.current.weather_code;
                root.condition = root.textFor(json.current.weather_code);
                root.highC = json.daily.temperature_2m_max[0];
                root.lowC = json.daily.temperature_2m_min[0];

                var now = new Date();
                var list = [];
                for (var i = 0; i < json.hourly.time.length && list.length < 8; i++) {
                    var t = new Date(json.hourly.time[i]);
                    if (t < now)
                        continue;
                    list.push({
                        hour: t.getHours(),
                        temp: Math.round(json.hourly.temperature_2m[i]),
                        code: json.hourly.weather_code[i]
                    });
                }
                root.hourly = list;
            } catch (e) {
                root.condition = "Weather unavailable";
            }
        };
        x.open("GET", url);
        x.send();
    }

    function locate() {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE)
                return;
            if (x.status === 200) {
                try {
                    var json = JSON.parse(x.responseText);
                    if (json.status === "success") {
                        root.fetchWeather(json.lat, json.lon);
                        return;
                    }
                } catch (e) {
                }
            }
            root.condition = "Weather unavailable";
        };
        x.open("GET", "http://ip-api.com/json?fields=status,lat,lon");
        x.send();
    }

    Component.onCompleted: locate()

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.locate()
    }

    MultiEffect {
        anchors.fill: card
        source: card
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.6)
        shadowBlur: 0.7
        shadowVerticalOffset: 10
        shadowHorizontalOffset: 0
        shadowOpacity: 0.5
        autoPaddingEnabled: true
        z: -1
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: root.surfaceContainer
        radius: 48
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        implicitWidth: layout.implicitWidth + layout.anchors.margins * 2
        implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 28
            spacing: 12

            Text {
                text: root.condition
                color: root.onSurface
                font.family: root.fontFamily
                font.pixelSize: 16
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 14

                Text {
                    font.family: "Material Symbols Rounded"
                    text: root.iconFor(root.currentCode)
                    font.pixelSize: 40
                    color: root.primary
                }

                Text {
                    text: isNaN(root.tempC) ? "--°" : Math.round(root.tempC) + "°C"
                    color: root.onSurface
                    font.family: root.fontFamily
                    font.pixelSize: 36
                    font.bold: true
                }
            }

            Text {
                text: isNaN(root.feelsLikeC) ? "" : "Feels like " + Math.round(root.feelsLikeC) + "°C"
                color: root.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 13
            }

            Text {
                text: (isNaN(root.highC) || isNaN(root.lowC)) ? "" : ("High " + Math.round(root.highC) + "° · Low " + Math.round(root.lowC) + "°")
                color: root.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 13
            }

            RowLayout {
                Layout.topMargin: 6
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                    model: root.hourly
                    delegate: ColumnLayout {
                        required property var modelData
                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.hour + ":00"
                            color: root.onSurfaceVariant
                            font.family: root.fontFamily
                            font.pixelSize: 10
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.family: "Material Symbols Rounded"
                            text: root.iconFor(modelData.code)
                            color: root.primary
                            font.pixelSize: 18
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.temp + "°"
                            color: root.onSurfaceVariant
                            font.family: root.fontFamily
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}

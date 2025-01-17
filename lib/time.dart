/// Simple class that represents a specific time in hours, minutes, and seconds.
/// 
/// You can use the [formatted] property to get the time formatted in an ``hh:mm:ss`` form.
/// You can also get the time as a [Duration] using the [asDuration] property.
class Time {
    static const Time zero = Time();

    final int hours;
    final int minutes;
    final int seconds;

    const Time({this.hours = 0, this.minutes = 0, this.seconds = 0});

    @override
    bool operator ==(Object other) => 
        other is Time && other.hours == hours && other.minutes == minutes && other.seconds == seconds;

    @override
    int get hashCode => hours.hashCode ^ minutes.hashCode ^ seconds.hashCode;

    // I'm sure this could be coded better but I kinda bodged it quickly.
    String get formatted {
        String hourText = (hours > 1) ? "${hours.toString().padLeft(2, '0')}:" : '';
        return "$hourText${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }

    Duration get asDuration => Duration(hours: hours, minutes: minutes, seconds: seconds);
}
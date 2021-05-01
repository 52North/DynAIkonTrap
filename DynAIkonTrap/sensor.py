# DynAIkonTrap is an AI-infused camera trapping software package.
# Copyright (C) 2020 Miklas Riechmann

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""
An interface to the sensor board. The logs from sensor readings are taken by the `SensorLogs` and can be accessed via the `SensorLogger.get()` function, by timestamp. The intended usage is to retrieve a sensor log taken at a similar time to a frame.
"""
from typing import List, Tuple, Type, Union
from typing import OrderedDict as OrderedDictType
from multiprocessing import Process, Queue
from multiprocessing.queues import Queue as QueueType
from dataclasses import dataclass
from time import time
from serial import Serial, SerialException
from collections import OrderedDict
from signal import signal, setitimer, ITIMER_REAL, SIGALRM

from DynAIkonTrap.logging import get_logger
from DynAIkonTrap.settings import SensorSettings

logger = get_logger(__name__)


@dataclass
class Reading:
    """Representation of a sensor reading, which has a value and units of measurement"""

    value: float
    units: str


@dataclass
class SensorLog:
    """A log of sensor readings taken at a given moment in time. `system_time` is represented as a UNIX-style timestamp. If a reading could not be taken for any of the attached sensors, the sensor may be represented by `None` in the log."""

    system_time: float
    ursense_id: 'Union[str, Type[None]]' = None
    brightness: 'Union[Reading, Type[None]]' = None
    humidity: 'Union[Reading, Type[None]]' = None
    pressure: 'Union[Reading, Type[None]]' = None
    temperature_skwt: 'Union[Reading, Type[None]]' = None
    temperature_prst: 'Union[Reading, Type[None]]' = None
    air_quality: 'Union[Reading, Type[None]]' = None
    gps_time: 'Union[str, Type[None]]' = None
    gps_location: 'Union[str, Type[None]]' = None
    altitude: 'Union[Reading, Type[None]]' = None
    sun_azimuth: 'Union[Reading, Type[None]]' = None
    sun_altitude: 'Union[Reading, Type[None]]' = None


def parse_ursense(data: str) -> Union[SensorLog, Type[None]]:
    """Parse the serial results output by a urSense 1.28 board as specified in the [user documentation v1.1](https://gitlab.dynaikon.com/dynaikontrap/urSense/-/blob/58de75992a6428abbf218e9f4d5fbbbd6a7babc7/ursense-user-manual-v1.pdf)

    Args:
        data (str): The serial data output from the urSense board
    Returns:
        Union[SensorLog, Type[None]]: The current data as a `SensorLog` or `None` if the input could not be parsed.
    """

    system_time = time()

    fields = data.split(' ')
    if fields[0] != 'selE':
        # This happens on start-up
        return None

    if len(fields) < 22:
        logger.warning('Expected at least 22 fields, got {}'.format(len(fields)))
        return None

    # Start with readings that are always available
    usid = fields[5]
    skwt = Reading(float(fields[7]), fields[8])
    brig = Reading(float(fields[10].strip('%')), '%')
    airr = Reading(float(fields[12]), fields[13])
    humi = Reading(float(fields[15].strip('%')), '%')
    atpr = Reading(float(fields[17]), fields[18])
    prst = Reading(float(fields[20]), fields[21])

    mode = fields[1]
    if mode == 'envm':
        if len(fields) != 22:
            logger.warning(
                'Expected 22 fields for type `envm`, got {}'.format(len(fields))
            )
            return None
        return SensorLog(
            system_time=system_time,
            ursense_id=usid,
            temperature_skwt=skwt,
            brightness=brig,
            air_quality=airr,
            humidity=humi,
            pressure=atpr,
            temperature_prst=prst,
        )

    elif mode == 'envt':
        # Environment with time
        raise NotImplementedError

    elif mode == 'envl':
        # Environment with location
        raise NotImplementedError

    elif mode == 'enve':
        # Environment with time and location
        raise NotImplementedError

    elif mode == 'envs':
        # Environment with time, location, altitude, and sun position
        if len(fields) != 37:
            logger.warning(
                'Expected 37 fields for type `envs`, got {}'.format(len(fields))
            )
            return None

        gps_time = ' '.join([fields[22], fields[23], fields[24], fields[25]])
        gps_location = ' '.join([fields[26], fields[27]])
        alti = Reading(float(fields[29]), fields[30])
        sazi = Reading(float(fields[32]), 'deg')
        salt = Reading(float(fields[35]), fields[36])
        return SensorLog(
            system_time=system_time,
            ursense_id=usid,
            temperature_skwt=skwt,
            brightness=brig,
            air_quality=airr,
            humidity=humi,
            pressure=atpr,
            temperature_prst=prst,
            gps_time=gps_time,
            gps_location=gps_location,
            altitude=alti,
            sun_azimuth=sazi,
            sun_altitude=salt,
        )

    else:
        logger.warning('Sensor reading invalid report type field')
        return None


class Sensor:
    """Provides an interface to the weather sensor board"""

    def __init__(self, port: str, baud: int):
        """
        Args:
            port (str): The path to the port to which the sensor is attached, most likely `'/dev/ttyUSB0'`
            baud (int): Baudrate to use in communication with the sensor board
        Raises:
            SerialException: If the sensor board could not be found
        """
        try:
            self._ser = Serial(port, baud, timeout=0)
        except SerialException:
            logger.warning('Sensor board not found on {}, baud {}'.format(port, baud))
            self._ser = None
            raise

    def _retrieve_latest_data(self) -> Union[SensorLog, Type[None]]:

        data = None

        if not self._ser:
            return None

        while self._ser.in_waiting:
            data = self._ser.readline()

        if not data:
            return None

        sensor_log = parse_ursense(str(data))
        if sensor_log == None:
            return None

        return sensor_log

    def read(self) -> SensorLog:
        """Triggers the taking and logging of sensor readings

        Returns:
            SensorLog: Readings for all sensors
        """
        latest = self._retrieve_latest_data()
        if latest == None:
            return SensorLog(system_time=time())
        return latest


class SensorLogs:
    """A data structure to hold all sensor logs. The class includes a dedicated process to perform the sensor logging and handle sensor log lookup requests."""

    def __init__(self, settings: SensorSettings):
        """
        Args:
            settings (SensorSettings): Settings for the sensor logger
        Raises:
            SerialException: If the sensor board could not be found
        """
        self._storage: OrderedDictType[float, SensorLog] = OrderedDict()
        self._query_queue: QueueType[float] = Queue()
        self._results_queue: QueueType[SensorLog] = Queue()

        try:
            self._sensor = Sensor(settings.port, settings.baud)
        except SerialException:
            self._sensor = None

        self._read_interval = settings.interval_s
        self._last_logged = 0

        self._logger = Process(target=self._log, daemon=True)
        self._logger.start()
        logger.debug('SensorLogs started')

    @property
    def read_interval(self):
        return self._read_interval

    def _log_now(self, delay=None, interval=None):
        if self._sensor is None:
            return
        sensor_log = self._sensor.read()
        logger.debug(sensor_log)
        self._storage[sensor_log.system_time] = sensor_log

    def _find_closest_key(
        self, sorted_keys: List[float], ts: float, index: int = 0
    ) -> Tuple[float, int]:

        if len(sorted_keys) == 1:
            return (sorted_keys[0], index)

        # Find numerically closest key of two
        if len(sorted_keys) == 2:
            mean_ts = sum(sorted_keys) / 2
            if ts >= mean_ts:
                return (sorted_keys[1], index + 1)
            else:
                return (sorted_keys[0], index)

        halfway = int(len(sorted_keys) // 2)
        halfway_ts = sorted_keys[halfway]

        # Normal bisecting
        if ts == halfway_ts:
            return (ts, halfway)
        elif ts > halfway_ts:
            return self._find_closest_key(sorted_keys[halfway:], ts, halfway)
        else:
            return self._find_closest_key(sorted_keys[: halfway + 1], ts, 0)

    def _lookup(self, timestamp: float) -> SensorLog:
        if self._sensor is None:
            return None

        keys = list(self._storage.keys())
        if len(keys) == 0:
            return None

        key, index = self._find_closest_key(keys, timestamp)

        # Delete all except current log as subsequent frames may still need this
        try:
            self._remove_logs(keys[:index])
        except KeyError as e:
            logger.error('Attempted to delete nonexistent log(s): {}'.format(e))
        return self._storage.get(key, None)

    def _remove_logs(self, timestamps: List[float]):
        """Removes all logs with the given `timestamp` keys."""
        for t in timestamps:
            del self._storage[t]

        if timestamps:
            logger.debug(
                'Deleted logs for {}\nRemaining: {}'.format(
                    timestamps, self._storage.keys()
                )
            )

    def _log(self):
        # Set up periodic temperature logging
        signal(SIGALRM, self._log_now)
        setitimer(ITIMER_REAL, 0.1, self._read_interval)

        while True:
            query = self._query_queue.get()
            self._results_queue.put_nowait(self._lookup(query))

    def get(self, timestamp: float) -> Union[SensorLog, type(None)]:
        """Get the log closest to the given timestamp and return it.

        Also deletes logs older than this timestamp.

        Args:
            timestamp (float): Timestamp of the image for which sensor readings are to be retrieved

        Returns:
            Union[SensorLog, None]: The retrieved log of sensor readings or `None` if none could be retrieved.
        """

        self._query_queue.put(timestamp)
        return self._results_queue.get()

    def close(self):
        self._logger.terminate()
        self._logger.join()

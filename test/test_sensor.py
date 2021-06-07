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
from time import sleep
from unittest import TestCase
from collections import OrderedDict

from DynAIkonTrap.sensor import Reading, SensorLogs, SensorLog, parse_ursense
from DynAIkonTrap.settings import SensorSettings


class SensorMock:
    def __init__(self):
        self._i = 0

    def read(self) -> SensorLog:
        ret = SensorLog(self._i, self._i + 1, self._i + 2, self._i + 3, self._i + 4)
        self._i += 5
        return ret


class LogNowAddsToLogsTestCase(TestCase):
    def setUp(self):
        class MySensorLogs(SensorLogs):
            def __init__(self):
                super().__init__(SensorSettings('', 0, 0.1))
                self._sensor = SensorMock()
                self._logger.terminate()

        self._sl = MySensorLogs()

    def test_logs_added(self):
        self._sl._log_now()
        self._sl._log_now()
        self._sl._log_now()
        self.assertEqual(self._sl._storage[0], SensorLog(0, 1, 2, 3, 4))
        self.assertEqual(self._sl._storage[5], SensorLog(5, 6, 7, 8, 9))
        self.assertEqual(self._sl._storage[10], SensorLog(10, 11, 12, 13, 14))


class RemoveLogsTestcase(TestCase):
    def setUp(self):
        class MySensorLogs(SensorLogs):
            def __init__(self):
                super().__init__(SensorSettings('', 0, 0.1))
                self._sensor = SensorMock()
                self._logger.terminate()

        self._sl = MySensorLogs()

    def test_remove_logs_when_none_exist(self):
        self._sl._storage.clear()
        with self.assertRaises(KeyError):
            self._sl._remove_logs([0])

    def test_remove_logs_with_given_timestamps(self):
        self._sl._storage.clear()
        self._sl._log_now()
        self._sl._log_now()
        self._sl._log_now()
        self._sl._remove_logs([0, 5])
        self.assertEqual(len(self._sl._storage), 1)
        self.assertEqual(self._sl._storage[10], SensorLog(10, 11, 12, 13, 14))


class FindKeyTestCase(TestCase):
    def setUp(self):
        class MySensorLogs(SensorLogs):
            def __init__(self):
                super().__init__(SensorSettings('', 0, 0.1))
                self._sensor = SensorMock()
                self._logger.terminate()

        self._sl = MySensorLogs()

    def test_find_exact_key(self):
        res = self._sl._find_closest_key([0.1, 1.1, 2.1], 0.1)
        self.assertEqual(res, (0.1, 0))

    def test_lookup_just_larger_than_key(self):
        res = self._sl._find_closest_key([0, 1, 2], 0.1)
        self.assertEqual(res, (0, 0))

    def test_lookup_just_smaller_than_key(self):
        res = self._sl._find_closest_key([0, 1, 2], 0.9)
        self.assertEqual(res, (1, 1))

    def test_only_one_key(self):
        res = self._sl._find_closest_key([0], 1)
        self.assertEqual(res, (0, 0))

    def test_lookup_smaller_than_smallest_entry(self):
        res = self._sl._find_closest_key([0, 1, 2], -1)
        self.assertEqual(res, (0, 0))

    def test_lookup_larger_than_largest_entry(self):
        res = self._sl._find_closest_key([0, 1, 2], 3)
        self.assertEqual(res, (2, 2))


class LookupAndDeleteTestCase(TestCase):
    def setUp(self):
        class MySensorLogs(SensorLogs):
            def __init__(self):
                super().__init__(SensorSettings('', 0, 0.1))
                self._sensor = SensorMock()
                self._logger.terminate()

        self._sl = MySensorLogs()

    def test_returns_closest_log1(self):
        self._sl._storage.clear()
        self._sl._log_now()
        self._sl._log_now()
        ret = self._sl._lookup(0.1)
        self.assertEqual(ret, SensorLog(0, 1, 2, 3, 4))

    def test_returns_closest_log2(self):
        self._sl._storage.clear()
        self._sl._log_now()
        self._sl._log_now()
        ret = self._sl._lookup(4.9)
        self.assertEqual(ret, SensorLog(5, 6, 7, 8, 9))

    def test_returns_closest_log3(self):
        self._sl._storage.clear()
        self._sl._log_now()
        self._sl._log_now()
        ret = self._sl._lookup(5.1)
        self.assertEqual(ret, SensorLog(5, 6, 7, 8, 9))

    def test_removes_only_logs_older_than_requested_time(self):
        self._sl._storage.clear()
        self._sl._log_now()
        self._sl._log_now()
        self._sl._lookup(5.1)
        self.assertEqual(len(self._sl._storage), 1)
        self.assertEqual(self._sl._storage, OrderedDict({5: SensorLog(5, 6, 7, 8, 9)}))


class ParseInvalidSensorTestCase(TestCase):
    def test_parse_envt_report_type(self):
        ret = parse_ursense(
            'urSense 1.28... commands:\n  e show environment sensor measurements\n  L toggle PPS on LED D5\n'
        )
        self.assertEqual(ret, None)


class ParseEnvmReportTypeTestCase(TestCase):
    def test_parse_envm_report_type(self):
        ret = parse_ursense(
            'selF envm 2.800 s usid 0123456789ab skwt 24.6 C brig 1.86% airr 4.69 kOhm humi 35.2% atpr 1002.8 mbar prst 25.3 C\n'
        )
        self.assertTrue(isinstance(ret.system_time, float))
        self.assertEqual(
            ret,
            SensorLog(
                system_time=ret.system_time,
                ursense_id='0123456789ab',
                brightness=Reading(1.86, '%'),
                humidity=Reading(35.2, '%'),
                pressure=Reading(1002.8, 'mbar'),
                temperature_skwt=Reading(24.6, 'C'),
                temperature_prst=Reading(25.3, 'C'),
                air_quality=Reading(4.69, 'kOhm'),
                gps_time=None,
                gps_location=None,
                altitude=None,
                sun_azimuth=None,
                sun_altitude=None,
            ),
        )


class ParseEnvtReportTypeTestCase(TestCase):
    def test_parse_envt_report_type(self):
        self.assertRaises(
            NotImplementedError,
            parse_ursense,
            'selE envt 2.800 s usid 0123456789ab skwt 24.6 C brig 1.86% airr 4.69 kOhm humi 35.2% atpr 1002.8 mbar prst 25.3 C\n',
        )


class ParseEnvlReportTypeTestCase(TestCase):
    def test_parse_envl_report_type(self):
        self.assertRaises(
            NotImplementedError,
            parse_ursense,
            'selE envl 2.800 s usid 0123456789ab skwt 24.6 C brig 1.86% airr 4.69 kOhm humi 35.2% atpr 1002.8 mbar prst 25.3 C\n',
        )


class ParseEnvsReportTypeTestCase(TestCase):
    def test_parse_envs_report_type(self):
        ret = parse_ursense(
            'selE envs 114.205 s usid 0123456789ab skwt 25.2 C brig 1.27% airr 5.47 kOhm humi 35.1% atpr 1003 mbar prst 25.7 C Fri 30.04.2021 20;25;20.123 E1+0000 50.36194N 4.74472W alti 108 m sazi 116.123 WNW salt -1.123 deg\n'
        )
        self.assertTrue(isinstance(ret.system_time, float))
        self.assertEqual(
            ret,
            SensorLog(
                system_time=ret.system_time,
                ursense_id='0123456789ab',
                brightness=Reading(1.27, '%'),
                humidity=Reading(35.1, '%'),
                pressure=Reading(1003, 'mbar'),
                temperature_skwt=Reading(25.2, 'C'),
                temperature_prst=Reading(25.7, 'C'),
                air_quality=Reading(5.47, 'kOhm'),
                gps_time='Fri 30.04.2021 20;25;20.123 E1+0000',
                gps_location='50.36194N 4.74472W',
                altitude=Reading(108, 'm'),
                sun_azimuth=Reading(116.123, 'deg'),
                sun_altitude=Reading(-1.123, 'deg'),
            ),
        )

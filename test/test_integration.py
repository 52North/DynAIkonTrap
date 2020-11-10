from time import time
from pickle import load
from multiprocessing import Queue, Value
from unittest import TestCase

from DynAIkonTrap.camera import Frame
from DynAIkonTrap.filtering import Filter
from DynAIkonTrap.comms import Sender
from DynAIkonTrap.sensor import SensorLogs
from DynAIkonTrap.settings import (
    OutputMode,
    SenderSettings,
    load_settings,
    OutputFormat,
)


def load_pickle(filename):
    with open(filename, 'rb') as f:
        data = load(f)
    return data


class MockCamera:
    def __init__(self, settings, data):
        self.framerate = settings.framerate
        self._data = data
        self._queue = Queue()
        for i, d in enumerate(self._data):
            self._queue.put(Frame(d['image'], d['motion'], i))

    def get(self):
        return self._queue.get(1)


class SenderMock(Sender):
    def __init__(self, settings, read_from):
        self.call_count = Value('i', 0)
        super().__init__(settings, read_from)

    def output_still(self, **kwargs):
        with self.call_count.get_lock():
            self.call_count.value += 1


class IntegrationSendStillsOutTestCase(TestCase):
    def test_integration_at_least_one_animal_frame(self):

        data = load_pickle('test/data/data.pk')

        settings = load_settings()
        settings.camera.framerate = data['framerate']
        settings.camera.resolution = data['resolution']
        settings.output = SenderSettings(0, OutputFormat.STILL, OutputMode.SEND, '', '')

        camera = MockCamera(settings.camera, data['frames'])
        filters = Filter(read_from=camera, settings=settings.filter)
        sensor_logs = SensorLogs(settings=settings.sensor)
        self.sender = SenderMock(
            settings=settings.output, read_from=(filters, sensor_logs)
        )


        t_start = time()

        while True:

            if self.sender.call_count.value >= 1:
                break

            if time() - t_start >= 50:
                self.fail('Timed out')

"""Desktop UI helpers for chat threads (feature-flagged)."""
import typing

import allure

import configs
import driver
from gui.elements.button import Button
from gui.elements.text_label import TextLabel
from gui.objects_map import messaging_names
from helpers.chat_helper import chat_contains_message_text


def thread_title_from_parent_message(parent_text: str) -> str:
    return parent_text[:50]


class ThreadPanel:
    def __init__(self):
        self._close_button = Button(messaging_names.closeThreadPanelButton)

    @property
    @allure.step('Thread side panel is open')
    def is_open(self) -> bool:
        return self._close_button.exists

    @allure.step('Close thread side panel')
    def close(self):
        self._close_button.wait_until_appears().click()
        timeout_msec = configs.timeouts.UI_LOAD_TIMEOUT_MSEC
        assert driver.waitFor(lambda: not self._close_button.exists, timeout_msec), (
            f'Thread panel did not close within {timeout_msec} ms'
        )


@allure.step('Active chat header title')
def active_chat_header_title() -> str:
    return TextLabel(messaging_names.statusChatInfoButton).text


@allure.step('Wait until chat header shows {expected!r}')
def wait_for_chat_header(expected: str, timeout_msec: int = configs.timeouts.UI_LOAD_TIMEOUT_MSEC):
    assert driver.waitFor(lambda: active_chat_header_title() == expected, timeout_msec), (
        f'Chat header did not become {expected!r} within {timeout_msec} ms; '
        f'last title was {active_chat_header_title()!r}'
    )


@allure.step('Wait until reply is absent from main chat transcript')
def wait_until_reply_not_in_main_chat(chat, reply_text: str):
    timeout_msec = configs.timeouts.MESSAGING_TIMEOUT_SEC * 1000
    assert driver.waitFor(
        lambda: not chat_contains_message_text(chat, reply_text),
        timeout_msec,
    ), f'Reply {reply_text!r} appeared in main chat transcript'


@allure.step('Wait until notifications count for {item_name!r} is at least {min_count}')
def wait_for_notifications_count(
        drop_area_real_name: dict,
        item_name: str,
        min_count: int,
        timeout_msec: int = configs.timeouts.MESSAGING_TIMEOUT_SEC * 1000,
) -> int:
    last_count: typing.Optional[int] = None

    def _ready() -> bool:
        nonlocal last_count
        last_count = list_item_notifications_count(drop_area_real_name, item_name)
        return last_count >= min_count

    assert driver.waitFor(_ready, timeout_msec), (
        f'Notifications for {item_name!r} did not reach {min_count}; last count was {last_count}'
    )
    return last_count or 0


def list_item_notifications_count(drop_area_real_name: dict, item_name: str) -> int:
    for obj in driver.findAllObjects(drop_area_real_name):
        if str(getattr(obj, 'objectName', '')) != item_name:
            continue
        list_item = getattr(obj, 'item', obj)
        return int(getattr(list_item, 'notificationsCount', 0) or 0)
    raise LookupError(f'Chat list item {item_name!r} not found')


def messages_list_notifications_count(chat_list_item_real_name: dict, item_name: str) -> int:
    real_name = dict(chat_list_item_real_name)
    real_name['objectName'] = item_name
    matches = driver.findAllObjects(real_name)
    if not matches:
        raise LookupError(f'Messages list item {item_name!r} not found')
    return int(getattr(matches[0], 'notificationsCount', 0) or 0)

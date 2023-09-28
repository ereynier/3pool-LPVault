// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Handler} from "./Handler.t.sol";

contract ActorManager is CommonBase, StdCheats, StdUtils {
    Handler[] public handlers;

    constructor(Handler[] memory _handlers) {
        handlers = _handlers;
    }

    function deposit(uint256 handlerIndex, uint256 depositAmount) external {
        handlerIndex = bound(handlerIndex, 0, handlers.length - 1);
        handlers[handlerIndex].deposit(depositAmount);
    }

    function withdraw(uint256 handlerIndex, uint256 lpAmount) external {
        handlerIndex = bound(handlerIndex, 0, handlers.length - 1);
        handlers[handlerIndex].withdraw(lpAmount);
    }

    function harvest(uint256 handlerIndex) external {
        handlerIndex = bound(handlerIndex, 0, handlers.length - 1);
        handlers[handlerIndex].harvest();
    }

    /* ===== Helper Functions ===== */


    function updateTimestamp(uint256 handlerIndex) public {
        handlerIndex = bound(handlerIndex, 0, handlers.length - 1);
        handlers[handlerIndex].updateTimestamp();
    }
}

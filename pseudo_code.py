def main():
    while True:
        num = 0
        total = 0
        prev_op = "+"
        first_press = False
        reset = False
        print(num)
        while not reset:
            btn = input()
            if btn == "n+":
                if not first_press:
                    num += 1
                else:
                    first_press = False
                print(num)
            elif btn == "n-":
                if not first_press:
                    num -= 1
                else:
                    first_press = False
                print(num)
            elif btn == "+":
                if prev_op == "+":
                    total += num
                else:
                    total -= num
                print(total)
                prev_op = "+"
                first_press = True
                num = 0
            elif btn == "-":
                if prev_op == "+":
                    total += num
                else:
                    total -= num
                print(total)
                prev_op = "-"
                first_press = True
                num = 0
            elif btn == "c":
                prev_op = "+"
                first_press = False
                num = 0
                print(num)
            elif btn == "ce":
                reset = True


def main2():
    while True:
        num = 0
        total = 0
        prev_op = "+"
        first_press = False
        reset = False
        print(num)
        while not reset:
            btn = input()
            if btn == "n+" or btn == "n-":
                if not first_press:
                    if btn == "n+":
                        num += 1
                    else:
                        num -= 1
                else:
                    first_press = False
                print(num)
            elif btn == "+" or btn == "-":
                if prev_op == "+":
                    total += num
                else:
                    total -= num
                print(total)
                prev_op = btn
                first_press = True
                num = 0
            elif btn == "c":
                prev_op = "+"
                first_press = False
                num = 0
                print(num)
            elif btn == "ce":
                reset = True


if __name__ == "__main__":
    main2()

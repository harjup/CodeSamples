using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;

//This project contains methods used to solve project euler problems 2, 20 and 24.

//Problem 2 wants the sum of all even numbered fibonacci numbers that do not exceed four million
//Problem 20 wants the sum of the digits in the number 100! (100 factorial)
//Problem 24 wants the millionth lexicographic premutation of the digits 1, 2 ,3 ,4 ,5 ,6 , 7, 8, and 9

//projecteuler.net/problem=2
//projecteuler.net/problem=20
//projecteuler.net/problem=24
namespace ProjectEuler
{
    class Program
    {
        static void Main()
        {
            Console.WriteLine("The sum of all even Fibonacci numbers that \n do not exceed four million is: " + Fibonacci() + "\n");

			BigInteger myFactorial = BigFactorial(100);
			long mySum = SumDigits(myFactorial);

            Console.WriteLine(@"The sum of the digits in 100! is " + mySum + ".");
		
            Console.WriteLine("There are " + Permutations() + " possible combinations of 1, 2, 3, 4, 5, 6, 7, 8, and 9.");
            Console.Read();
        }

		//Recursive function used to calculate factorials for numbers 
		//that require more digitals than integers allow for
        static BigInteger BigFactorial(BigInteger i)
        {
            if (i == 1)
            {
                return 1;
            }

            return i * BigFactorial(i - 1);
        }

        static long SumDigits(BigInteger i)
        {
            string s = i.ToString();
            return s.Sum(c => Convert.ToInt64(c.ToString()));
        }

		
        //Calculates the sum of all even fibonacci terms that don't exceed 4 million
        static int Fibonacci()
        {
            int num1 = 1;       //First fibonacci term
            int num2 = 2;       //Second fibonacci term
            int numC = 0;       //Current fibonacci term
            int sum = 2;        //Running total of all even terms

            while (numC < 4000000)
            {
                numC = num1 + num2;

                if (numC % 2 == 0)
                {
                    sum += numC;
                }

                num1 = num2;
                num2 = numC;
            }

            return sum;
        }

        //Calculates factorials that are possible within the limits of the integer datatype
        static int Factorial(int i)
        {
            if (i == 1)
            {
                return 1;
            }

            return i * Factorial(i - 1);
        }

        //Finds the millionth permutation of the numbers 0-9, using Combinatorics
        //
        //Based on an algorith found at mathblog.dk/project-euler-24-millionth-lexicographic-permutation/
        //Which also includes an explaination of how it works
        static string Permutations()
        {
            var numbers = 
                new List<int> { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };      //First permutation of 0-9
            int N = numbers.Count;                                   //Used to start calculations at the end of the list instead of the beginning
            string permNum = "";
            int remainder = 1000000 - 1;                             //Amount of permutations remaining

   
            for (int i = 1; i < N; i++)
            {
                int j = remainder / Factorial(N - i);  
                remainder = remainder % Factorial(N - i);
                permNum = permNum + numbers[j];
                numbers.RemoveAt(j);

                if (remainder == 0)
                    break;
            }


            for (int i = 0; i < numbers.Count; i++)
                permNum = permNum + numbers[i];

            return permNum;
        }


    }
}

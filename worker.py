import argparse

def parse_arg():
    """
    This function parses command line arguments to this script
    """
    parser = argparse.ArgumentParser()

    parser.add_argument("--user_id", type=int, default=1)
    parser.add_argument("--document_id", type=int, default=2)
    parser.add_argument("--s3_document_path", type=str,required=True)

    params = vars(parser.parse_args())

    return params

if __name__ == "__main__":
    params = parse_arg()
    print(f"dummy job working with params: {params}")
